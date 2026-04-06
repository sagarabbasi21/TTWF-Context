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
