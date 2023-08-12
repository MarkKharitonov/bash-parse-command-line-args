# bash-parse-command-line-args
A script to parse command line arguments AND generate the help text based on a JSON argument spec.

# Rationale
### C#
I have a very pleasant experience parsing command line arguments in C# with the help of the wonderful [Mono.Options](https://www.nuget.org/packages/Mono.Options) package. It allows to declare the spec for the command line arguments declaratively and automatically generates a nice looking help text. Which is extremely convenient. Much recommended.

### Powershell
There is a lot to say about Powershell, both good and bad, but one thing is sure for me - they nailed it with the way they handle command line arguments to scripts and functions. An effortless experience, very convenient.

### bash
Many examples I saw include 3 elements (more or less):
 - a call to `getopt` or `getopts` (or some other equivalent)
 - a big loop with a case statement inside
 - a separate help function outputting the help text

Of course, it is on us to make sure the help text accurately reflects what we parse in the loop. 

This is not the way I am used to parse command line arguments. I want a solution satisfying the following conditions:
 1. The supported command line options are declared using a specification.
 1. The help text is to be generated automatically from the specification.
 1. An option can be declared as required.
 1. An option can be declared as having a mandatory value.

[This StackOverflow question](https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash) seems to have a few answers that do that. I consolidated them in [my own answer](https://stackoverflow.com/a/76889923/80002), where I am linking to the answers which give the respective solutions. 

They are likely better than mine, but I wanted to try it anyway :-).

Internally, my script uses the `getopt` bash command AND it depends on the `jq` tool, because the command line argument spec is in JSON.

# Examples
The repository contains an example script ([example.sh](https://github.com//MarkKharitonov/bash-parse-command-line-args/blob/master/example.sh)) showing off the capabilities of my command line parser:

### Missing required argument
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh
example.sh: a required option is missing (-n | --name | --app-name)

/c/work/bash-parse-command-line-args (master)$
```

### Get help
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh -h
Command line options:

-h, --help                      Show this help text
-n, --name, --app-name=value    [REQUIRED] A comma separated list of application names or the keyword 'all' to run the given build for all the relevant applications
-b, --build=value               [REQUIRED] A build definition name
    --nn, --no-navigate         Do not navigate to the build pages
-p, --plan                      Plan only, do not apply
-s, --skip, --skip-internal-dns Skip the internal DNS stages

/c/work/bash-parse-command-line-args (master)$
```

### A valid compact command line
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh -psn xyz -b mybuild --nn
APP_NAME=xyz
BUILD_DEF_NAME=mybuild
NO_NAVIGATE=1
TERRAFORM_PLAN=1
SKIP_INTERNAL_DNS=1

/c/work/bash-parse-command-line-args (master)$
```

### A valid long command line
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh --plan --app-name xyz --build mybuild --no-navigate --skip-internal-dns
APP_NAME=xyz
BUILD_DEF_NAME=mybuild
NO_NAVIGATE=1
TERRAFORM_PLAN=1
SKIP_INTERNAL_DNS=1

/c/work/bash-parse-command-line-args (master)$
```

### A valid command line with only required arguments
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh --app xyz -b mybuild
APP_NAME=xyz
BUILD_DEF_NAME=mybuild
NO_NAVIGATE=
TERRAFORM_PLAN=
SKIP_INTERNAL_DNS=

/c/work/bash-parse-command-line-args (master)$
```

### Unknown option
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh --app xyz -b mybuild -k
example.sh: unknown option -- k

/c/work/bash-parse-command-line-args (master)$
```

### Missing option value
```
/c/work/bash-parse-command-line-args (master)$ ./example.sh --app xyz -b
example.sh: option requires an argument -- b

/c/work/bash-parse-command-line-args (master)$
```

# Conclusion
I am very much interested in improving the quality and the performance of my script, so any relevant Pull Requests are more than welcome.
