## Description

<!-- Provide a clear and concise description of your changes -->

## Type of Change

<!-- Put an 'x' in all the boxes that apply -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Other (please describe):

## Checklist

- [ ] I have read the [CONTRIBUTING](../CONTRIBUTING.md) document
- [ ] My code follows the code style of this project
- [ ] I have added tests to cover my changes (if applicable)
- [ ] All new and existing tests pass
- [ ] **I have added a changie for this PR** (run `changie new` to create one)

## Additional Context

<!-- Add any other context about the pull request here -->

---

### About Changie

This project uses [Changie](https://changie.dev) to manage changelog entries. Please add a changelog entry for your changes by running:

```bash
changie new
```

This will prompt you to select the type of change and provide a description. The generated file should be committed with your PR.

If you don't have Changie installed, you can:
- Install it from [changie.dev](https://changie.dev)
- Or manually create a file in `.changes/unreleased/` following the existing format
