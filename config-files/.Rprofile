user_error_text <- "Error in user : "

assignment_user_error <- function(var, value) {
  stop(user_error_text, "use `<-` instead.")
}

# We don't need six ways to assign to a variable.
"=" <- assignment_user_error
"->" <- assignment_user_error
"<<-" <- assignment_user_error
"->>" <- assignment_user_error

# Why is this even a thing?
T <- paste(
  user_error_text,
  "use TRUE instead.",
  sep = "",
  collapse = NULL
)
F <- paste(
  user_error_text,
  "use FALSE instead.",
  sep = "",
  collapse = NULL
)

options(prompt = "R> ", continue = "R+ ")
