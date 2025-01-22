String cmajorDocs = """
Below is a **condensed** overview of the main concepts and syntax in the Cmajor (Cmaj) language.

## Language Overview

- **Purpose**: Cmaj is a safe, statically typed language for real-time DSP (Digital Signal Processing). It avoids crashes or real-time rule violations, compiles to native speeds comparable to C/C++, and uses a syntax that will feel familiar to anyone with C/C++/Java/JavaScript experience.
- **Key Units**:
  - **Processors**: Contain DSP code, stateful variables, `main()` loops, and I/O endpoints for streams, events, and values.
  - **Graphs**: Wire processors together into signal flows, optionally with oversampling, delays, or feedback loops.
  - **Namespaces**: Collect processors, graphs, types, and constants.

## Lexical & Basic Syntax

- **Whitespace** is mostly ignored (use spaces for indentation).
- **Comments**: `/* ... */` (multi-line) and `//` (single-line).
- **Identifiers**: `[A-Za-z][A-Za-z0-9_]*`; case-sensitive.
- **Keywords**: A set of reserved words (`bool, break, case, catch, class, ...`) cannot be used as identifiers.

## Types

1. **Primitives**: `int32 (int), int64, float32 (float), float64, complex32 (complex), complex64, bool`.
2. **Limited-range Integers**: `wrap<N>` (modulo) and `clamp<N>` (clamped) for safe array indexing.
3. **Complex**: `complex32` or `complex64`, with imaginary literals (`0.5i`).
4. **Arrays**: `T[size]`. Bounds are compile-time constants. Out-of-range indices wrap or emit a performance warning unless using a `wrap<N>` index.
5. **Slices**: `T[]`; reference sub-arrays without copying. Cannot outlive the array that backs them.
6. **Vectors**: `T<4>`, etc. for small, fixed-size numeric collections with possible SIMD optimization.  
7. **Structs**: Declared with `struct { ... }`, all members zero-initialized. Can include member functions.
8. **Enums**: Typed enumerations with no implicit integer casts.
9. **References**: `T&` parameters, restricted to avoid dangling references.
10. **Type Aliases**: `using MyInt = int64;`.
11. **Metafunctions**: Compile-time helpers like `.size`, `.elementType`, `isFloat`, `isArray`, etc.

## Literals & Initialization

- **Integers**: Decimal, hex (`0x`), binary (`0b`). `L` or `_i64` suffix for 64-bit.  
- **Floats**: `123.0`, `123.0f`, `123.0_f64` etc.  
- **Strings**: JSON-style escapes in double quotes.  
- **Aggregates**: `(val1, val2, ...)` to initialize arrays/structs.  
- **Null/Zero**: `()` to reset any type to zero/empty.

## Functions

- **Syntax**: `returnType name (params) { ... }`
- **Member Functions**: Inside structs or as free functions taking the struct as the first parameter.
- **`main()`** in a processor: The real-time DSP loop, typically calling `advance()` each frame.
- **`init()`**: Optional setup code for a processor, runs before `main()`.
- **Recursion**: Not allowed (ensures predictable stack size).
- **Generics**: `functionName<Type>(...)` with compile-time pattern matching. `static_assert` can check constraints on generic parameters.

## Variables & Constants

- **Local**: `var` (mutable), `let` (constant), or standard declarations (`int x = 1;`).
- **State Variables** in processors: Declared at the processor’s top level. Persist across frames.
- **Global Constants**: Inside namespaces only (cannot store non-constant global data).
- **`external`**: Values or functions whose definitions are provided by the host environment.

## Control Flow

- **`while`, `for`, `loop (n)`, `if/else`, `break`, `continue`, `switch/case`** behave as in C/C++-style languages.
- **`loop`** can be infinite (`loop { ... }`) or fixed (`loop (N)`).
- **`if const`**: Compile-time conditionals for branching code paths in generics.

## Operators

- **Arithmetic**: `+ - * / % **` (exponent), prefix/postfix `++ --`.
- **Bitwise**: `& | ^ ~ << >> >>>`.
- **Logical**: `&& || !`.
- **Comparison**: `< <= > >= == !=`.
- **Casts**: Functional style, e.g. `int(x)` or `float<4>(someVector)`.

## Processors

- **Definition**: 
  ```
  processor Name
  {
      input/output endpoints...
      state variables...
      functions (incl. main())...
  }
  ```
- **Endpoints**: 
  - `stream T` (sample-accurate, single scalar or vector),
  - `value T` (non-sample-accurate, can be smoothly interpolated),
  - `event T` (triggered events, with optional handler `event endpointName (T val)`).
- **Writing Output**: `myOutput <- value;`
- **`console`**: Special event output for debugging/logging.

## Graphs

- **Definition**: 
  ```
  graph Name
  {
      input/output endpoints...
      node child = ProcessorName [optional parameters] * oversamplingFactor;
      connection statements...
  }
  ```
- **Nodes**: Instances of processors (including optional arrays or oversampling).
- **Connections**: `sourceEndpoint -> destinationEndpoint`, with possible chaining (`-> child -> out`) and optional `[delay]` or `[resamplingPolicy]`.
- **Hoisting**: Expose child node endpoints at the graph’s top-level with `output child.out*;`
- **Feedback Loops**: Allowed if at least a 1-sample delay is inserted.

## Special Topics

- **Over/Under-sampling**: Attach `* factor` or `/ factor` to a node. Streams are automatically resampled.
- **Latency**: A processor can declare `processor.latency = N;` to indicate its internal delay. The graph will auto-compensate alignment.
- **Annotations**: `[[ key: value ]]` blocks attached to processors, endpoints, variables, etc. for metadata.

## Built-in Constants & Intrinsics

- **Constants**: `nan`, `inf`, `pi`, `twoPi`, plus `processor.frequency`, `processor.period`, etc.
- **Common Functions**: `abs`, `sqrt`, `sin`, `cos`, `pow`, `min`, `max`, `lerp`, etc.

## Native Linking (Advanced)

- **`external` Functions**: Can map directly to host-provided C functions if parameter/return types match.

## Example

// Determine the note frequency from the pitch (midi note)
processor Sine [[ main, width: 80, height: 60 ]]
{
    input value float32 frequency [[ pinTop: 10 ]];
    output stream float32 out [[ pinTop: 10 ]];

    // Constants
    const float32 PI = 3.14159265358979323846f;
    const float32 TWO_PI = 2.0f * PI;
    const float32 SAMPLE_RATE = 44100.0f;

    // State variables
    float32 phase = 0.0;

    void main()
    {
        loop {
            // Generate sine wave
            float32 sample = sin(TWO_PI * phase);

            // Output the sample
            out <- sample;

            // Increment phase
            phase = phase + (frequency / SAMPLE_RATE);
            if (phase >= 1.0) {
                phase = phase - 1.0f;
            }

            advance();
        }
    }
}
""";
