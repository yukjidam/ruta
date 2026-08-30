import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Hardcoded placeholder data so every screen renders something real-looking
/// without a backend. Swap these for actual model/repository calls later.

class DummyRide {
  final String title;
  final String date;
  final String duration;
  final String distanceLabel;
  final List<DummyRider> riders;
  final int hearts;
  final int comments;
  final bool heartedByMe;

  /// A short rider-written blurb about the ride. Blank by default — set
  /// on the Seal the Ride composer, shown read-only on the ride detail
  /// screen.
  final String caption;

  /// The actual comments on this ride. Kept separate from the `comments`
  /// count above (that's the badge shown on the card before you open the
  /// ride) so the detail screen has real content to display instead of
  /// every ride sharing one generic comment list.
  final List<DummyComment> commentList;

  const DummyRide({
    required this.title,
    required this.date,
    required this.duration,
    required this.distanceLabel,
    required this.riders,
    this.hearts = 0,
    this.comments = 0,
    this.heartedByMe = false,
    this.caption = '',
    this.commentList = const [],
  });
}

class DummyRider {
  final String initials;
  final Color color;
  final String name;
  final String subtitle;

  const DummyRider({
    required this.initials,
    required this.color,
    this.name = '',
    this.subtitle = '',
  });
}

class DummyBike {
  final String name;
  final String year;
  final String odometer;
  final Color color;

  const DummyBike({
    required this.name,
    required this.year,
    required this.odometer,
    required this.color,
  });
}

/// A single comment on a ride post. Sample data only — the comment sheet
/// keeps whatever gets "posted" in local widget state, so it resets next
/// time the sheet opens. Swap for a real comments table later.
class DummyComment {
  final String initials;
  final Color color;
  final String name;
  final String text;

  const DummyComment({
    required this.initials,
    required this.color,
    required this.name,
    required this.text,
  });
}

/// A full rider profile — used for both "your own" profile (id: 'me')
/// and any friend's/searched rider's profile, since it's the same screen
/// either way. `rides` is that person's own logbook, shown on their
/// profile with heart/comment actions.
class DummyProfile {
  final String id;
  final String name;
  final String username;
  final String initials;
  final Color color;
  final String kmLogged;
  final String ridesCount;
  final List<DummyBike> bikes;
  final List<DummyRide> rides;
  final bool isFriend;

  const DummyProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.initials,
    required this.color,
    required this.kmLogged,
    required this.ridesCount,
    required this.bikes,
    required this.rides,
    this.isFriend = false,
  });
}

const dummyRides = [
  DummyRide(
    title: 'Coastal run to Anawangin',
    date: 'SAT, AUG 9',
    duration: '4H 12M',
    distanceLabel: '142 KM · ZAMBALES',
    riders: [
      DummyRider(initials: 'JM', color: AppColors.route),
      DummyRider(initials: 'KR', color: AppColors.pine),
      DummyRider(initials: '+2', color: AppColors.rust),
    ],
    hearts: 24,
    comments: 5,
    caption: 'Left before sunrise to beat the heat on the Zambales coast road. '
        'Water was unreal at Anawangin — already planning the next one.',
    commentList: [
      DummyComment(
          initials: 'KR',
          color: AppColors.pine,
          name: 'Kim Reyes',
          text: 'This road never gets old 🔥'),
      DummyComment(
          initials: 'MT', color: AppColors.rust, name: 'Mar Tan', text: 'Bring me next time!'),
      DummyComment(
          initials: 'AL',
          color: AppColors.asphalt3,
          name: 'Al Santos',
          text: 'That sunset shot though 😍'),
      DummyComment(
          initials: 'PS',
          color: AppColors.asphalt3,
          name: 'Pat Sison',
          text: 'Which route did you take up?'),
      DummyComment(
          initials: 'RC',
          color: AppColors.rust,
          name: 'Rey Cruz',
          text: 'Zambales gang assemble 🏍️'),
    ],
  ),
  DummyRide(
    title: 'Early morning Marilaque',
    date: 'WED, AUG 5',
    duration: '1H 40M',
    distanceLabel: '58 KM · SOLO',
    riders: [
      DummyRider(initials: 'JM', color: AppColors.route),
    ],
    hearts: 12,
    comments: 2,
    caption: 'Quick solo loop before work. Empty roads, cold air, perfect way to start the day.',
    commentList: [
      DummyComment(
          initials: 'KR',
          color: AppColors.pine,
          name: 'Kim Reyes',
          text: 'Teach me your wake-up-early ways'),
      DummyComment(
          initials: 'RC',
          color: AppColors.rust,
          name: 'Rey Cruz',
          text: 'Marilaque at dawn hits different'),
    ],
  ),
];

/// A placeholder "just finished" ride, used only by the Capture Memory →
/// Seal the Ride composer flow until real live-ride tracking exists to
/// supply actual stats. Distance/duration/riders stand in for what a real
/// GPS session will eventually report; caption starts blank since that's
/// what the rider fills in on the composer.
const dummyJustCompletedRide = DummyRide(
  title: '',
  date: 'TODAY',
  duration: '2H 14M',
  distanceLabel: '67 KM · TAGAYTAY',
  riders: [
    DummyRider(initials: 'JM', color: AppColors.route),
    DummyRider(initials: 'KR', color: AppColors.pine),
    DummyRider(initials: 'MT', color: AppColors.rust),
    DummyRider(initials: 'AL', color: AppColors.asphalt3),
  ],
  hearts: 0,
  comments: 0,
);

const dummyBikes = [
  DummyBike(name: 'Mio Sporty', year: '2017', odometer: '51,204 KM', color: AppColors.pine),
  DummyBike(name: 'Honda CB150R', year: '2021', odometer: '12,880 KM', color: AppColors.rust),
];

const dummySampleComments = [
  DummyComment(
    initials: 'KR',
    color: AppColors.pine,
    name: 'Kim Reyes',
    text: 'This road never gets old 🔥',
  ),
  DummyComment(
    initials: 'MT',
    color: AppColors.rust,
    name: 'Mar Tan',
    text: 'Bring me next time!',
  ),
  DummyComment(
    initials: 'AL',
    color: AppColors.asphalt3,
    name: 'Al Santos',
    text: 'That sunset shot though 😍',
  ),
];

/// Every rider account in the demo. `id: 'me'` is the signed-in user;
/// everyone else is either crew (isFriend: true) or a searchable stranger
/// (isFriend: false). Crew, Search, and Profile screens all read from
/// this single list so the data stays consistent across the app.
const dummyProfiles = [
  DummyProfile(
    id: 'me',
    name: 'Juan M.',
    username: '@juanmrides',
    initials: 'JM',
    color: AppColors.route,
    kmLogged: '1,204',
    ridesCount: '18',
    bikes: dummyBikes,
    rides: dummyRides,
    isFriend: true,
  ),
  DummyProfile(
    id: 'kim',
    name: 'Kim Reyes',
    username: '@kimrdrives',
    initials: 'KR',
    color: AppColors.pine,
    kmLogged: '860',
    ridesCount: '11',
    bikes: [
      DummyBike(name: 'Mio Sporty', year: '2019', odometer: '30,410 KM', color: AppColors.pine),
    ],
    rides: [
      DummyRide(
        title: 'Sunrise chase, Batangas',
        date: 'SUN, AUG 3',
        duration: '2H 05M',
        distanceLabel: '76 KM · SOLO',
        riders: [DummyRider(initials: 'KR', color: AppColors.pine)],
        hearts: 41,
        comments: 6,
      ),
    ],
    isFriend: true,
  ),
  DummyProfile(
    id: 'mar',
    name: 'Mar Tan',
    username: '@martanrides',
    initials: 'MT',
    color: AppColors.rust,
    kmLogged: '2,310',
    ridesCount: '27',
    bikes: [
      DummyBike(name: 'Honda CB150R', year: '2021', odometer: '18,220 KM', color: AppColors.rust),
    ],
    rides: [
      DummyRide(
        title: 'Night ride, Skyway loop',
        date: 'FRI, AUG 1',
        duration: '1H 12M',
        distanceLabel: '39 KM · SOLO',
        riders: [DummyRider(initials: 'MT', color: AppColors.rust)],
        hearts: 18,
        comments: 2,
      ),
    ],
    isFriend: true,
  ),
  DummyProfile(
    id: 'al',
    name: 'Al Santos',
    username: '@alsantos',
    initials: 'AL',
    color: AppColors.asphalt3,
    kmLogged: '412',
    ridesCount: '6',
    bikes: [
      DummyBike(
          name: 'Yamaha Aerox', year: '2022', odometer: '8,900 KM', color: AppColors.asphalt3),
    ],
    rides: [
      DummyRide(
        title: 'Weekend Antipolo loop',
        date: 'SAT, JUL 26',
        duration: '1H 40M',
        distanceLabel: '52 KM · SOLO',
        riders: [DummyRider(initials: 'AL', color: AppColors.asphalt3)],
        hearts: 9,
        comments: 1,
      ),
    ],
    isFriend: false,
  ),
  DummyProfile(
    id: 'pat',
    name: 'Pat Sison',
    username: '@patsison',
    initials: 'PS',
    color: AppColors.asphalt3,
    kmLogged: '95',
    ridesCount: '2',
    bikes: [],
    rides: [],
    isFriend: false,
  ),
  DummyProfile(
    id: 'rey',
    name: 'Rey Cruz',
    username: '@reycruz17',
    initials: 'RC',
    color: AppColors.rust,
    kmLogged: '640',
    ridesCount: '9',
    bikes: [
      DummyBike(
          name: 'Kawasaki KLX150', year: '2020', odometer: '15,050 KM', color: AppColors.rust),
    ],
    rides: [
      DummyRide(
        title: 'Trail run, Sierra Madre',
        date: 'WED, JUL 23',
        duration: '3H 30M',
        distanceLabel: '64 KM · OFF-ROAD',
        riders: [DummyRider(initials: 'RC', color: AppColors.rust)],
        hearts: 33,
        comments: 4,
      ),
    ],
    isFriend: false,
  ),
];
