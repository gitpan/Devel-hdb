## Devel::hdb

A Perl graphical debugger that uses an HTTP REST interface

## Usage

Start a program with the debugger

    shell> perl -d:hdb yourprogram.pl
    Debugger listening on http://127.0.0.1:8080/

Tell the debugger to use a different port

    shell> perl -d:hdb=port:9876 yourprogram.pl
    Debugger listening on http://127.0.0.1:9876

## How to use it

Operation of the interface should be straightforward, though there are a few
controls that may not be obvious.

### Breakpoints and actions

Clicking on a line number will toggle an unconditional breakpoint for that line.
Right-clicking on a line number will bring up a form to enter a breakpoint
expression and action.  When the expression evaluates true, the debugger will
stop on that line.

A line number with a red circle is an unconditional breakpoint.  A blue circle
is a conditional breakpoint.  The circle is outlined if that line has an action.

### Watch Expressions

Click on the "+" to add a new watch expression.

Double-click on an existing expression to edit the expression.

For arrays, hashes and globs, click on the blue circle to collapse/expand it

## Features

* Single step, step over, step out, continue and exit the debugged program
* Set breakpoints dynamically in the running program
* Inspect the current position at any level in the call stack
* Watch variables/expressions
* Get control when the process exits

Pretty much what you would expect from any debugger.

### Planned Features

* Get notification when the debugged process forks, with options to debug the
    child process, or allow it to continue
* Get notification of untrapped exceptions, and stop at the exception point
* Inspect lexical variables in higher stack frames
* Step into an arbitrary expression
* Restart execution at some prior execution point

## Implementation

The debugger is split into three major parts.

* Devel::hdb::DB - Implements the debugger functions like DB::DB and DB::sub
* Devel::hdb::App - Implements the REST interface.  It is a Plack app, and uses
    HTTP::Server::PSGI as the web server
* The user interface is HTML and JavaScript code that lives under Devel/hdb/html/.
    It makes requests to the REST interface.
