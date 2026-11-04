# GitHub issues

Use this layout for every addon in this workspace. The issue is the spec. A later build follows the issue.

Refine one issue at a time. Approval writes the new body to that GitHub issue and stops. It does not start the addon work.

Use the `enhancement` label for an enhancement. These repos have no GitHub issue type named Enhancement.

## Sections

### Description

The story. Who uses it, what they can do when it is done, and what happens today. A few sentences. One concrete example is enough.

### Scope

#### In scope

The behaviors this issue includes. One behavior per bullet.

#### Out of scope

The behaviors this issue leaves alone. Name the other issue when one already covers that behavior.

### Acceptance criteria

Checks a person can try and mark pass or fail. One check per bullet. These are the bars for done. They are testable actions. They are not a second copy of In scope.

### Notes

Optional. Facts already known, and questions still open. API field names and current file names belong here. Leave this section off when there is nothing to record.

## One story

If In scope has two stories, split the issue before writing the body.

## Leave the build out

Menu names, settings, and pass/fail checks belong in the issue. File edits, branch names, and a version bump do not.

## Template

```markdown
## Description

## Scope

### In scope

-

### Out of scope

-

## Acceptance criteria

- [ ]

## Notes
```
