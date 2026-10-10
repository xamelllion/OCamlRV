# OCamlRV

OCamlRV is an interpreter for a small subset of OCaml. It includes a parser,
an error-reporting Hindley-Milner type inferencer, and an evaluator with
support for recursive values and functions.

The project is implemented in OCaml and uses Dune as its build system.

## Features

- Integer, boolean, string, `unit`, list, option, and tuple values
- Arithmetic, comparison, equality, boolean, and unary operators
- `if` expressions and `match` expressions
- Anonymous functions, function application, and partial application
- Pattern matching with variables, constants, lists, cons cells, tuples, and
	type annotations
- Non-recursive and recursive `let` bindings, including mutually recursive
	bindings
- Let-polymorphism and static type inference
- Parse-tree output and interpreter debug output

## Requirements

- OCaml
- Dune
- The dependencies listed in `OCamlRV.opam`

For an opam-based setup, install the project dependencies with:

```sh
opam install . --deps-only
```

## Building

Build the project with Dune:

```sh
dune build
```

The executable is available as `bin/main.exe` after building.

## Usage

The runner reads a source file passed as its positional argument. At least one
operation flag should be supplied:

```sh
dune exec -- main path/to/program.ml -interpret
```

Available flags:

| Flag | Description |
| --- | --- |
| `-interpret` | Evaluate the program and print its output |
| `-inference` | Infer the types in the program and report type errors |
| `-dparsetree` | Print the parsed representation of the program |
| `-debug` | Enable interpreter debug output |

Several flags can be combined. For example, to inspect the parse tree and then
interpret the example program:

```sh
dune exec -- main bin/example.ml -dparsetree -interpret
```

The runner can also read a program from standard input when no input filename
is given:

```sh
printf 'let x = 2 + 3\n' | dune exec -- main -inference
```

Example program:

```ocaml
let rec factorial n =
	if n <= 1 then 1 else n * factorial (n - 1)

let () = print_int (factorial 5)
```

## Testing and development

Run the Dune test suite, including cram tests:

```sh
dune runtest
```

The Makefile provides common development targets:

```sh
make          # Build the project
make fmt      # Format and promote formatting changes
make lint     # Run Dune lint checks
make zanuda   # Run checks, tests, and Zanuda
```

The `zanuda` target uses [Zanuda](https://github.com/Kakadu/zanuda).

Property-based tests can be run through the QuickCheck executable:

```sh
dune exec -- quickcheck
```

## Project structure

- `lib/ast.ml` - abstract syntax tree definitions
- `lib/parser.ml` - source parser
- `lib/inferencer.ml` - type inference
- `lib/interpreter.ml` - evaluator
- `bin/main.ml` - command-line runner
- `manytests.t/` - typed and ill-typed example programs
- `tests/` - unit and property-based test support

## License

OCamlRV is distributed under the LGPL-3.0-or-later license. See
`COPYING.LESSER` for the license text.

Copyright 2024-2025 Viacheslav Sidorov and Danila Rudnev-Stepanyan.
