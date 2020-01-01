# mdexec

Execute shell scripts in markdown files using pandoc.

Uses an `exec` attribute to distinguish executable shell scripts and choose which
one to run.

For example, a script can be defined as:

```{.bash exec=install}
echo "Hello world!"
exit 42
```

And executed as:

```
$ mdexec README.md install
Hello World!
$ echo $?
42
```
