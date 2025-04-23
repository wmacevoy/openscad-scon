/*
 * json2scon.c — Read JSON on stdin, output SCON on stdout using cJSON.
 * Usage:
 *   ./json2scon [--fmt=FMT] [--fmt FMT]
 * where FMT must contain "{scon}" (default: "{scon}").
 */

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include "cJSON.h"  // https://github.com/DaveGamble/cJSON
 
 /* ——— Dynamic string builder ——— */
 typedef struct {
     char *buf;
     size_t len, cap;
 } sb_t;
 
 /* Initialize builder */
 static void sb_init(sb_t *s) {
     s->len = 0;
     s->cap = 1024;
     s->buf = malloc(s->cap);
     if (!s->buf) {
         perror("malloc");
         exit(1);
     }
     s->buf[0] = '\0';
 }
 
 /* Ensure there's room for extra bytes; double capacity if needed */
 static void sb_grow(sb_t *s, size_t extra) {
     size_t need = s->len + extra + 1;
     if (need > s->cap) {
         size_t newcap = need * 2;
         char *tmp = realloc(s->buf, newcap);
         if (!tmp) {
             perror("realloc");
             free(s->buf);
             exit(1);
         }
         s->buf = tmp;
         s->cap = newcap;
     }
 }
 
 /* Append a C-string */
 static void sb_append(sb_t *s, const char *text) {
     size_t l = strlen(text);
     sb_grow(s, l);
     memcpy(s->buf + s->len, text, l);
     s->len += l;
     s->buf[s->len] = '\0';
 }
 
 /* Append a single character */
 static void sb_append_char(sb_t *s, char c) {
     sb_grow(s, 1);
     s->buf[s->len++] = c;
     s->buf[s->len] = '\0';
 }
 
 /* Finalize and shrink buffer to fit exactly */
 static char *sb_finalize(sb_t *s) {
     char *tmp = realloc(s->buf, s->len + 1);
     if (!tmp && s->len + 1 > 0) {
         perror("realloc");
         free(s->buf);
         exit(1);
     }
     s->buf = tmp ? tmp : s->buf;
     return s->buf;
 }
 
 /* ——— Escape one character per SCON rules ——— */
 static void scon_char(sb_t *s, unsigned char cp) {
     if (cp >= 32 && cp <= 127) {
         if (cp == '\\') { sb_append(s, "\\\\"); return; }
         if (cp == '"')  { sb_append(s, "\\\""); return; }
         sb_append_char(s, (char)cp);
     }
     else if (cp <= 0xFF) {
         if (cp == '\n') { sb_append(s, "\\n"); return; }
         if (cp == '\r') { sb_append(s, "\\r"); return; }
         if (cp == '\t') { sb_append(s, "\\t"); return; }
         char tmp[5];
         snprintf(tmp, sizeof(tmp), "\\x%02x", cp);
         sb_append(s, tmp);
     } else {
         /* we only emit \uXXXX for BMP; beyond BMP we still use \uXXXX */
         char tmp[7];
         snprintf(tmp, sizeof(tmp), "\\u%04x", cp & 0xFFFF);
         sb_append(s, tmp);
     }
 }
 
 /* ——— Emit a quoted & escaped string ——— */
 static void scon_string(sb_t *s, const char *str) {
     sb_append_char(s, '"');
     for (const unsigned char *p = (const unsigned char*)str; *p; ++p) {
         scon_char(s, *p);
     }
     sb_append_char(s, '"');
 }
 
 /* ——— Recursive JSON→SCON conversion ——— */
 static void scon_from_json(cJSON *item, sb_t *s) {
     if (cJSON_IsNull(item)) {
         sb_append(s, "undef");
     }
     else if (cJSON_IsBool(item)) {
         sb_append(s, cJSON_IsTrue(item) ? "true" : "false");
     }
     else if (cJSON_IsNumber(item)) {
         char numbuf[64];
         if (item->valuedouble == (double)item->valueint)
             snprintf(numbuf, sizeof(numbuf), "%lld", (long long)item->valueint);
         else
             snprintf(numbuf, sizeof(numbuf), "%.*g", 15, item->valuedouble);
         sb_append(s, numbuf);
     }
     else if (cJSON_IsString(item)) {
         scon_string(s, item->valuestring);
     }
     else if (cJSON_IsArray(item)) {
         sb_append_char(s, '[');
         int first = 1;
         cJSON *el;
         cJSON_ArrayForEach(el, item) {
             if (!first) sb_append(s, ", ");
             first = 0;
             scon_from_json(el, s);
         }
         sb_append_char(s, ']');
     }
     else if (cJSON_IsObject(item)) {
         sb_append_char(s, '[');
         int first = 1;
         for (cJSON *child = item->child; child; child = child->next) {
             if (!first) sb_append(s, ", ");
             first = 0;
             sb_append_char(s, '[');
             scon_string(s, child->string);
             sb_append(s, ", ");
             scon_from_json(child, s);
             sb_append_char(s, ']');
         }
         sb_append_char(s, ']');
     }
 }
 
 /* ——— Read all stdin into builder ——— */
 static char *read_stdin(void) {
     sb_t sb;
     sb_init(&sb);
     int ch;
     while ((ch = getchar()) != EOF) {
         sb_append_char(&sb, (char)ch);
     }
     if (ferror(stdin)) {
         perror("stdin read");
         exit(1);
     }
     return sb_finalize(&sb);
 }
 
 int main(int argc, char *argv[]) {
     /* Default format */
     const char *fmt = "{scon}";
 
     /* Parse --fmt= and --fmt FMT */
     for (int i = 1; i < argc; i++) {
         if (strncmp(argv[i], "--fmt=", 6) == 0) {
             fmt = argv[i] + 6;
         }
         else if (strcmp(argv[i], "--fmt") == 0 && i + 1 < argc) {
             fmt = argv[++i];
         }
     }
 
     /* Read JSON text */
     char *json_text = read_stdin();
 
     /* Parse JSON */
     cJSON *root = cJSON_Parse(json_text);
     free(json_text);
     if (!root) {
         fprintf(stderr, "JSON parse error at: %s\n", cJSON_GetErrorPtr());
         return 1;
     }
 
     /* Build SCON */
     sb_t sb;
     sb_init(&sb);
     scon_from_json(root, &sb);
     cJSON_Delete(root);
     char *scon = sb_finalize(&sb);
 
     /* Ensure placeholder */
     if (!strstr(fmt, "{scon}")) {
         fprintf(stderr, "Error: format string must include \"{scon}\".\n");
         free(scon);
         return 1;
     }
 
     /* Output with replacements */
     const char *p = fmt;
     while ((p = strstr(p, "{scon}"))) {
         /* write text before placeholder */
         fwrite(fmt, 1, p - fmt, stdout);
         /* write SCON */
         fwrite(scon, 1, sb.len, stdout);
         /* advance past placeholder */
         p += 6;
         fmt = p;
     }
     /* write any trailing format text */
     fputs(fmt, stdout);
     fputc('\n', stdout);
 
     free(scon);
     return 0;
 }