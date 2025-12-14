String authErrorMessage(String code) {
  final normalized = code.startsWith('auth/') ? code.substring(5) : code;

  switch (normalized) {
    case 'admin-restricted-operation':
      return 'This operation is restricted to administrators only.';
    case 'argument-error':
      return 'Invalid arguments were provided.';
    case 'app-not-authorized':
      return 'This app is not authorized to use Firebase Authentication.';
    case 'app-not-installed':
      return 'The requested app is not installed.';
    case 'captcha-check-failed':
      return 'Captcha verification failed.';
    case 'code-expired':
      return 'The verification code has expired.';
    case 'credential-already-in-use':
      return 'This credential is already associated with another account.';
    case 'custom-token-mismatch':
      return 'The custom token corresponds to a different audience.';
    case 'requires-recent-login':
      return 'Please log in again to perform this operation.';
    case 'dynamic-link-not-activated':
      return 'Dynamic links are not activated for this app.';
    case 'email-already-in-use':
      return 'This email address is already in use.';
    case 'email-change-needs-verification':
      return 'Email change needs verification.';
    case 'expired-action-code':
      return 'The action code has expired.';
    case 'internal-error':
      return 'An internal error occurred. Please try again later.';
    case 'invalid-api-key':
      return 'Invalid API key.';
    case 'invalid-app-credential':
      return 'Invalid app credential.';
    case 'invalid-app-id':
      return 'Invalid app ID.';
    case 'invalid-user-token':
      return 'Invalid user token.';
    case 'invalid-auth-event':
      return 'Invalid authentication event.';
    case 'invalid-cert-hash':
      return 'Invalid certificate hash.';
    case 'invalid-verification-code':
      return 'Invalid verification code.';
    case 'invalid-continue-uri':
      return 'Invalid continue URI.';
    case 'invalid-custom-token':
      return 'Invalid custom token.';
    case 'invalid-dynamic-link-domain':
      return 'Invalid dynamic link domain.';
    case 'invalid-email':
      return 'The email address is invalid.';
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'wrong-password':
      return 'The password is incorrect.';
    case 'invalid-phone-number':
      return 'Invalid phone number.';
    case 'invalid-provider-id':
      return 'Invalid provider ID.';
    case 'invalid-recipient-email':
      return 'Invalid recipient email.';
    case 'invalid-sender':
      return 'Invalid sender.';
    case 'invalid-verification-id':
      return 'Invalid verification ID.';
    case 'invalid-tenant-id':
      return 'Invalid tenant ID.';
    case 'multi-factor-info-not-found':
      return 'Multi-factor info not found.';
    case 'multi-factor-auth-required':
      return 'Multi-factor authentication is required.';
    case 'missing-app-credential':
      return 'Missing app credential.';
    case 'missing-verification-code':
      return 'Missing verification code.';
    case 'missing-continue-uri':
      return 'Missing continue URI.';
    case 'missing-ios-bundle-id':
      return 'Missing iOS bundle ID.';
    case 'missing-or-invalid-nonce':
      return 'Missing or invalid nonce.';
    case 'missing-phone-number':
      return 'Missing phone number.';
    case 'missing-verification-id':
      return 'Missing verification ID.';
    case 'app-deleted':
      return 'The app has been deleted.';
    case 'account-exists-with-different-credential':
      return 'Account exists with different credentials.';
    case 'network-request-failed':
      return 'Network request failed.';
    case 'no-such-provider':
      return 'No such provider exists.';
    case 'operation-not-allowed':
      return 'This operation is not allowed.';
    case 'popup-blocked':
      return 'Popup blocked.';
    case 'popup-closed-by-user':
      return 'Popup closed by user.';
    case 'provider-already-linked':
      return 'This provider is already linked to the account.';
    case 'quota-exceeded':
      return 'Quota exceeded.';
    case 'redirect-cancelled-by-user':
      return 'Redirect cancelled by user.';
    case 'redirect-operation-pending':
      return 'A redirect operation is already pending.';
    case 'rejected-credential':
      return 'The credential was rejected.';
    case 'second-factor-already-in-use':
      return 'Second factor already in use.';
    case 'maximum-second-factor-count-exceeded':
      return 'Maximum second factor count exceeded.';
    case 'tenant-id-mismatch':
      return 'Tenant ID mismatch.';
    case 'timeout':
      return 'The operation timed out.';
    case 'user-token-expired':
      return 'User token has expired.';
    case 'too-many-requests':
      return 'Too many requests. Try again later.';
    case 'unauthorized-continue-uri':
      return 'Unauthorized continue URI.';
    case 'unsupported-first-factor':
      return 'Unsupported first factor.';
    case 'unsupported-persistence-type':
      return 'Unsupported persistence type.';
    case 'unsupported-tenant-operation':
      return 'Unsupported tenant operation.';
    case 'unverified-email':
      return 'Email address is not verified.';
    case 'user-cancelled':
      return 'User cancelled the operation.';
    case 'user-not-found':
      return 'No user found with this email.';
    case 'user-disabled':
      return 'This user has been disabled.';
    case 'user-mismatch':
      return 'User mismatch error.';
    case 'user-signed-out':
      return 'User has been signed out.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'web-storage-unsupported':
      return 'Web storage is not supported.';
    default:
      return 'An unknown error occurred.';
  }
}
