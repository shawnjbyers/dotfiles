fuckup_text <- "you fucked up."

assignment_fuckup <- function(var, value) {
    stop(fuckup_text, " use `<-` instead.")
}

# we don't need six ways to assign to a variable
"=" <- assignment_fuckup
"->" <- assignment_fuckup
"<<-" <- assignment_fuckup
"->>" <- assignment_fuckup

# why the fuck is this even a thing
T <- paste(fuckup_text, " use TRUE instead.", sep = "", collapse=NULL)
F <- paste(fuckup_text, " use FALSE instead.", sep = "", collapse=NULL)

options(prompt = "R> ", continue = "R+ ")
