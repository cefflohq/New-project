# In-app Google sign-in (google_sign_in → Credential Manager): keep the Play
# Services credential provider and Google ID classes it loads at runtime.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
