/// Broad classification of a mini-app used for launcher grouping, analytics
/// bucketing and category-level feature flags.
///
/// [other] is the forward-compatibility bucket for verticals that do not fit
/// any existing label — prefer adding a dedicated value over mislabelling.
enum MiniAppCategory {
  /// Ride-hailing, taxi, scooters, car rentals.
  transport,

  /// Restaurant ordering, groceries, meal delivery.
  food,

  /// Parcel and courier delivery.
  delivery,

  /// Wallets, transfers, cards, bill pay.
  payments,

  /// E-commerce, marketplaces, retail.
  commerce,

  /// Healthcare, pharmacy, appointments.
  health,

  /// Events, cinema, transport tickets.
  ticketing,

  /// Civic services and government portals.
  government,

  /// Telco top-ups, roaming, data plans.
  telco,

  /// Household utilities (electricity, gas, water).
  utilities,

  /// Media, streaming, games.
  entertainment,

  /// Courses, tutoring, exam prep.
  education,

  /// Community, messaging, social graphs.
  social,

  /// Anything that does not fit the above.
  other,
}
