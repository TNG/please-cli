# Contributing

Contributions are very welcome. The following will provide some helpful guidelines.

## How to contribute

If you want to tackle an existing issue please add a comment to make sure the issue is sufficiently discussed
and that no two contributors collide by working on the same issue. 
To submit a contribution, please follow the following workflow:

* Fork the project
* Create a feature branch
* Add your contribution
* Create a Pull Request

### Commits

Commit messages should be clear and fully elaborate the context and the reason of a change.
Each commit message should follow the following conventions:

* it may use markdown to improve readability on GitHub
* it should start with a title
  * less than 70 characters
  * starting lowercase
* if the commit is not trivial the title should be followed by a body
  * separated from the title by a blank line
  * explaining all necessary context and reasons for the change
* if your commit refers to an issue, please post-fix it with the issue number, e.g. `#123` or `Resolves #123`

A full example:

```
Fix calculation of menu state

Due to operator precedence, `$(( $menu_state ± 1 % 3 ))`
was basically equivalent to `$(( $menu_state ± 1 ))`.

Also change 1-based `menu_state` to 0-based `selected_option_index`
to be able to directly use modulo arithmetics.

Resolves #7
```

Furthermore, commits must be signed off according to the [DCO](DCO).

### Testing

Install [bats](https://bats-core.readthedocs.io/en/stable/installation.html).

Run tests:
```
bats --formatter pretty test
```