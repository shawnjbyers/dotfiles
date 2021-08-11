#include <stdio.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <libgen.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>

#define EXIT_OP_ERROR 1
#define EXIT_USER_ERROR 2
#define EXIT_INTERNAL_ERROR 3

const char *bname = "datetime";

void
print_usage(void)
{
  fprintf(stderr, "usage: %s [-h]\n", bname);
}

int
main(int argc, char *argv[])
{
  if (argc < 0) {
    fprintf(stderr, "%s: cannot access command line arguments\n", bname);
    return EXIT_USER_ERROR;
  }

  bname = basename(argv[0]);

  char c;
  while ((c = getopt(argc, argv, "h")) != -1) {
    switch (c) {
    case 'h':
      print_usage();
      return 0;
    case '?':
      print_usage();
      return EXIT_USER_ERROR;
    default:
      fprintf(stderr, "%s: internal error: unrecognized option %c\n", bname, c);
      return EXIT_INTERNAL_ERROR;
    }
  }

  time_t rawtime;
  struct tm time_info;
  size_t offsetstr_len = 40;
  char *offsetstr = malloc(offsetstr_len);
  if (offsetstr == NULL) {
    fprintf(stderr, "%s: out of memory\n", bname);
    return EXIT_OP_ERROR;
  }

  if (time(&rawtime) == (time_t)-1) {
    fprintf(stderr, "%s: failed to get time\n", bname);
    return EXIT_OP_ERROR;
  }

  if (localtime_r(&rawtime, &time_info) == NULL) {
    char err_buf[30];
    if (strerror_r(errno, err_buf, sizeof(err_buf)) != 0) {
      fprintf(stderr, "%s: failed printing localtime error\n", bname);
      return EXIT_OP_ERROR;
    }
    fprintf(stderr, "%s: localtime: %s\n", bname, err_buf);
    return EXIT_OP_ERROR;
  }

  while (strftime(offsetstr, offsetstr_len, "%FT%T\xff\xff%z", &time_info) == 0) {
    if (offsetstr_len < 1000) {
      offsetstr_len = offsetstr_len * 2;
      free(offsetstr);
      offsetstr = malloc(offsetstr_len);
      if (offsetstr == NULL) {
        fprintf(stderr, "%s: out of memory while printing time string\n", bname);
        return EXIT_OP_ERROR;
      }
      continue;
    }

    fprintf(stderr, "%s: failed to print time\n", bname);
    return EXIT_OP_ERROR;
  }

  bool found_minus = false;
  char *tmp_minus = "\xff\xff-";
  char *minus_sign = "\xe2\x88\x92";

  for (size_t i = 0; i < offsetstr_len - 2; i++) {
    if (memcmp(offsetstr + i, tmp_minus, strlen(tmp_minus)) == 0) {
      found_minus = true;
      memcpy(offsetstr + i, minus_sign, strlen(minus_sign));
      break;
    }
  }

  if (!found_minus) {
    fprintf(stderr, "%s: internal error: could not replace hyphen with minus sign\n", bname);
    return EXIT_INTERNAL_ERROR;
  }

  puts(offsetstr);
  free(offsetstr);
}
