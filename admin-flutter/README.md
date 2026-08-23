# Flutter admin bootstrap

Only app-owned source files are included in this scaffold. Generate platform folders on your machine, then keep these `lib`, `test`, `pubspec.yaml`, and `analysis_options.yaml` files.

From the repository root:

```powershell
Set-Location admin-flutter
flutter create --platforms=windows,android,web --project-name cinnamon_clay_admin .
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

If `flutter create` replaces the source files, restore the repository versions with Git before running the app.

This first slice is read-only. Authentication and CRUD are intentionally deferred to the OIDC/RBAC slice so that we do not create a fake "production" login implementation.
