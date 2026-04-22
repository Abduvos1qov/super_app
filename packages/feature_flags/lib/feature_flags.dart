/// Default implementations of the `FeatureFlagService` contract declared in
/// `mini_app_sdk`. The shell composes one or more of these to build its
/// feature-flag pipeline without leaking vendor SDKs into mini-apps.
library;

export 'src/composite_feature_flag_service.dart';
export 'src/in_memory_feature_flag_service.dart';
export 'src/static_feature_flag_service.dart';
export 'src/typed_flag.dart';
