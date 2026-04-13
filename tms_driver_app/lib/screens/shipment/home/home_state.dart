class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final String? username;
  final String? systemBannerMessage;
  final bool systemBannerIsMaintenance;
  final bool systemBannerHasInfo;
  final HomeShiftVm shift;
  final HomeCurrentTripVm? currentTrip;
  final List<HomeUpdateVm> updates;
  final List<String> layoutOrder; // Section keys in display order
  final Set<String> visibleSections; // Set of visible section keys

  const HomeState({
    required this.isLoading,
    required this.shift,
    this.errorMessage,
    this.username,
    this.systemBannerMessage,
    this.systemBannerIsMaintenance = false,
    this.systemBannerHasInfo = false,
    this.currentTrip,
    this.updates = const <HomeUpdateVm>[],
    this.layoutOrder = const [],
    this.visibleSections = const {},
  });

  factory HomeState.initial() {
    return const HomeState(
      isLoading: true,
      shift: HomeShiftVm(startTime: '', endTime: ''),
    );
  }

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? username,
    String? systemBannerMessage,
    bool? systemBannerIsMaintenance,
    bool? systemBannerHasInfo,
    HomeShiftVm? shift,
    HomeCurrentTripVm? currentTrip,
    bool clearCurrentTrip = false,
    List<HomeUpdateVm>? updates,
    List<String>? layoutOrder,
    Set<String>? visibleSections,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      username: username ?? this.username,
      systemBannerMessage: systemBannerMessage ?? this.systemBannerMessage,
      systemBannerIsMaintenance:
          systemBannerIsMaintenance ?? this.systemBannerIsMaintenance,
      systemBannerHasInfo: systemBannerHasInfo ?? this.systemBannerHasInfo,
      shift: shift ?? this.shift,
      currentTrip: clearCurrentTrip ? null : (currentTrip ?? this.currentTrip),
      updates: updates ?? this.updates,
      layoutOrder: layoutOrder ?? this.layoutOrder,
      visibleSections: visibleSections ?? this.visibleSections,
    );
  }
}

class HomeShiftVm {
  final bool onDuty;
  final String startTime;
  final String endTime;

  const HomeShiftVm({
    this.onDuty = true,
    required this.startTime,
    required this.endTime,
  });
}

class HomeCurrentTripVm {
  final String dispatchId;
  final String loadNumber;
  final String routeLabel;
  final String etaLabel;
  final double progress;
  final String progressLabel;

  const HomeCurrentTripVm({
    required this.dispatchId,
    required this.loadNumber,
    required this.routeLabel,
    required this.etaLabel,
    required this.progress,
    required this.progressLabel,
  });
}

class HomeUpdateVm {
  final int? id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? targetUrl;

  const HomeUpdateVm({
    this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.targetUrl,
  });
}
