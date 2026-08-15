class AppConstants {
  const AppConstants._();

  static const String supabaseUrl = 'https://wijzbweilibjrxptyjvs.supabase.co';
  static const String supabasePublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indpanpid2VpbGlianJ4cHR5anZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MzU2OTQsImV4cCI6MjEwMjMxMTY5NH0.iVfZc1__Ul1oc2koLmkZDVqX6_4uN68mf5Lt1dvnaSw';
}

class HiveBoxes {
  const HiveBoxes._();

  static const String authBox = 'auth_box';
  static const String onboardingBox = 'onboarding_box';
  static const String assignmentsBox = 'assignments_box';
}

class HiveKeys {
  const HiveKeys._();

  static const String cachedUser = 'CACHED_USER';
  static const String hasCompletedOnboarding = 'HAS_COMPLETED_ONBOARDING';
  static const String cachedAssignments = 'CACHED_ASSIGNMENTS';
}
