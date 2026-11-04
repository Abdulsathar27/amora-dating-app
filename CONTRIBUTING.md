# Contributing to Amora

Thanks for helping! Here is how to get a change merged.

## Setup

```bash
git clone https://github.com/Abdulsathar27/amora-dating-app.git
cd amora-dating-app
flutter pub get
flutter run   # uses the built-in mock API
```

## Workflow

1. Open an issue first for anything larger than a small fix.
2. Create a branch from `main`: `feature/short-name` or `fix/short-name`.
3. Make your change, then run:
   ```bash
   dart format --line-length 120 lib test
   flutter analyze
   flutter test
   ```
4. Open a pull request and fill in the template.

## Code rules

- **Views are `StatelessWidget` only.** Put any changing value in a Bloc or Cubit
  (use `ValueCubit<T>` for small dialog or sheet drafts).
- **Follow MVVM:** View → ViewModel (`features/*/view_model`) → Repository (`data/repositories`) → `DioClient`.
  Views never call repositories or Dio directly.
- **New endpoints:** add the path to `ApiEndpoints`, the method to a repository, a fake response to
  `MockInterceptor`, and document it in `docs/API_CONTRACT.md`.
- **Tests:** add a `bloc_test` for new Bloc logic.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(chat): add read receipts
fix(discovery): stop double swipe while card animates
docs: update API contract for photo upload
```
