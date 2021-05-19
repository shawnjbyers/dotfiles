#include <stdio.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <libgen.h>
#include <unistd.h>

#define EXIT_OP_ERROR 1
#define EXIT_USER_ERROR 2
#define EXIT_INTERNAL_ERROR 3

const char *bname = "utc-offset";

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
  char offsetstr[10];

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

  if (strftime(offsetstr, sizeof(offsetstr), "%z", &time_info) == 0) {
    fprintf(stderr, "%s: failed to print time\n", bname);
    return EXIT_OP_ERROR;
  }

  puts(offsetstr);
}
