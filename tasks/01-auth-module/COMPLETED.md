# Auth Module — COMPLETED
> Completed: 2026-04-02

## What was done

### Backend
- **Email login**: `authflow/serializers.py` — TokenObtainPairSerializer now authenticates by email (not username)
- **View updated**: `authflow/views.py` — TokenObtainPairView uses GenericAPIView with public access
- **Forgot password cleanup**: `authflow/signals.py` — improved email template, added logging
- **Celery task retry**: `authflow/tasks.py` — added max_retries=3 with 60s delay, error logging
- **App config**: `authflow/apps.py` — renamed to AuthflowConfig, added ready() for signals
- **Settings**: `settings/base.py` — added SERVER_ADDR default

### Frontend
- **Login page**: `pages/Login.jsx` — email field, Yup validation, UI matches login.html mockup
- **Forgot password**: `pages/ForgotPassword.jsx` — fixed typos, UI matches forgot-password.html mockup
- **Reset password**: `pages/ResetPassword.jsx` — responsive, password error display, consistent UI
- **Reusable components updated**:
  - `TextBox.jsx` — added `icon` prop, `onBlur` prop, updated styling
  - `Button.jsx` — added `fullWidth` prop, updated padding
  - `Card.jsx` — updated to rounded-2xl shadow-xl style
- **Validation**: `ValidationSchema.js` — added loginValidationSchema
- **Logout bug fix**: `auth.slice.jsx` — now clears both access AND refresh tokens
- **ESLint**: `.eslintrc.json` — disabled linebreak-style for Windows compatibility

## Key decisions
- No new fonts added — using existing project fonts
- All pages use reusable components (TextBox, Button, Card)
- SERVER_ADDR configurable via env.py (defaults to localhost:3000)

## 2026-04-15 — Manager discussion follow-up

### P0
- **BUG-29 / TASK-067** `StrictJWTAuthentication` (authflow/authentication.py) extends SimpleJWT — rejects token when `user_profile.deleted_at` is set with `user_deleted` code. Wired into `REST_FRAMEWORK.DEFAULT_AUTHENTICATION_CLASSES`. `UserProfile.soft_delete` now also sets `user.is_active=False`. Frontend axios response interceptor clears token + redirects on 401 with codes `user_inactive` / `user_deleted` / `user_not_found`.
- **BUG-02 / TASK-060** `CELERY_BROKER_URL` now reads env var; when empty → `CELERY_TASK_ALWAYS_EAGER=True` + `CELERY_TASK_EAGER_PROPAGATES=True` so emails fire synchronously in-process. `DEFAULT_FROM_EMAIL = EMAIL_HOST_USER` added. Verified via `manage.py check`.

### P1
- **BUG-06 / TASK-078** `TokenObtainPairSerializer` returns distinct `inactive_account` code with message "User is inactive. Please contact administrator." for `is_active=False`, soft-deleted profile, or `status != 'active'`. Wrong-password still returns `no_active_account`.
- **BUG-23 / TASK-084** App.jsx bootstrap fires a single `GET /users/me/` when a token exists and merges fresh `permissions` + `has_global_access` + `must_change_password` into Redux via `updateAuthUser`. Backend `/users/me/` now returns `permissions` map too. No polling.
- **CHG-07 / TASK-072** Shared password validator: `Backend/user_management/validators.py` + `Frontend/src/utils/helpers/passwordRules.js`. Rule: min 8 chars with upper, lower, digit, special. Wired in change-password endpoint, /users/me/ PUT, and all create/edit flows.
- **BUG-27 / TASK-087** `ChangePassword.jsx` now maps `err.response.data.detail` containing "current password" to `fieldErrors.current_password` so wrong-current errors render on the field.
