This project is a sample iOS application that demonstrates the feasibility of
issuing a Core Data fetch request that sorts on an aggregate key applied to a
given relationship. It shows a possible implementation for [this StackOverflow
answer][so-answer].

### Implementation

The original [StackOverflow question][so-question] asked whether it was possible
to fetch instances of a given entity (e.g. "Parent") based on an aggregate of
its related instances (e.g. "the count of its children"). To explore this
possibility, this app:

* Constructs a model programmatically with Parent and Child entities
* Establishes a to-many relationship `children` from Parent to Child, with an
  inverse `parent` relationship
* Inserts two parents, one with two children and one with one, into a store
* Fetches parents sorted by their number of children and logs the results

This last step is performed using the KVC aggregate key path `children.@count`.
These steps are repeated for each of the three supported model types on iOS:
binary, in-memory, and SQLite.

### Results

Both the binary and in-memory stores support this aggregate operation, correctly
returning both inserted Parent instances sorted by their count of children. The
SQLite store, on the other hand, throws an exception while attempting to prepare
a new SQL statement that matches the fetch request. Testing was not performed
using the XML store type, since that is only available on OS X.

### License

This sample project and all code it contains is available under the [Creative
Commons Attribution-ShareAlike 4.0 license][cc-by-sa-4.0]. The only exception is
the `.gitignore` file, which was obtained from [GitHub's gitignore
repo][gitignore] and has [its own license][gitignore-license].

[so-question]: http://stackoverflow.com/q/2448252/104200
[so-answer]: http://stackoverflow.com/a/2448378/104200
[cc-by-sa-4.0]: http://creativecommons.org/licenses/by-sa/4.0/
[gitignore]: https://github.com/github/gitignore
[gitignore-license]: https://github.com/github/gitignore/blob/master/LICENSE
