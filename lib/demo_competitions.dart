import 'models.dart';

class DemoCompetitions {
  static const categories = [
    'Football',
    'Basketball',
    'Volleyball',
    'Tennis',
    'Running',
    'Swimming',
    'Martial Arts',
    'Esports',
    'Table Tennis',
    'Chess',
    'Badminton',
    'Cycling',
    'Athletics',
    'MMA',
    'Wrestling',
  ];

  static final List<CompetitionItem> all = _buildAll();

  static List<CompetitionItem> byCategory(String category) {
    return all.where((item) => item.category == category).toList();
  }

  static String imageFor(String category, int index) {
    final images = _configs[category]?.images;
    if (images == null || images.isEmpty) {
      return _imageUrl('sports,competition', 9000 + index);
    }
    return images[index % images.length];
  }

  static List<CompetitionItem> _buildAll() {
    final items = <CompetitionItem>[];
    for (var categoryIndex = 0; categoryIndex < categories.length; categoryIndex++) {
      final category = categories[categoryIndex];
      final config = _configs[category]!;
      for (var eventIndex = 0; eventIndex < _eventTypes.length; eventIndex++) {
        final type = _eventTypes[eventIndex];
        final start = DateTime(2026, 6 + (categoryIndex ~/ 3), 7 + eventIndex * 4);
        final end = start.add(Duration(days: type.durationDays));
        final deadline = start.subtract(const Duration(days: 5));
        final limit = config.baseLimit + eventIndex * config.limitStep;
        final prize = config.prizes[eventIndex];

        items.add(
          CompetitionItem(
            id: 'demo-${_slug(category)}-${eventIndex + 1}',
            title: '${config.titlePrefix} ${type.name}',
            subtitle: '${config.shortName} ${type.subtitle}',
            fullDescription:
                '${config.shortName} төрлийн ${type.name.toLowerCase()} форматтай, бүрэн дүрэмтэй, оноолт болон бүртгэлийн хяналттай тэмцээн. Оролцогчид цагийн хуваарь, техникийн шаардлага, шүүлтийн журмыг урьдчилан баталгаажуулж оролцоно.',
            category: category,
            tags: [category, type.tag, config.scope],
            scope: config.scope,
            participationType: config.participationType,
            organizerType: 'Байгууллага',
            organizationName: config.organizer,
            fee: type.fee,
            materials:
                'Иргэний үнэмлэх, багийн мэдүүлэг, эрүүл мэндийн зөвшөөрөл, шаардлагатай спортын хэрэгсэл.',
            imageUrl: config.images[eventIndex % config.images.length],
            posterUrl: config.images[(eventIndex + 1) % config.images.length],
            linkText: 'https://competition.example.com/${_slug(category)}',
            ownerId: 'demo-admin',
            ownerEmail: 'admin@competition.example.com',
            status: 'approved',
            registrationStart: start,
            registrationEnd: end,
            registrationDeadline: deadline,
            createdAt: DateTime(2026, 5, 1 + eventIndex),
            location: config.locations[eventIndex % config.locations.length],
            ageCategory: config.ageGroups[eventIndex % config.ageGroups.length],
            maxParticipants: limit,
            maxTeamMembers: config.participationType == 'Багийн' ? 5 : 1,
            genderCategory:
                eventIndex == 1 ? 'Эрэгтэй' : eventIndex == 2 ? 'Эмэгтэй' : 'Бүх хүйс',
            prizes: prize,
            rules:
                '${config.shortName} холбооны үндсэн дүрэм, fair play зарчим, цагийн хуваарийг мөрдөнө. Хоцролт, бүртгэл дутуу материал болон зохисгүй үйлдэл нь хасагдах үндэслэл болно.',
            contactInfo:
                '${config.contactName} | ${config.contactPhone} | ${config.contactEmail}',
          ),
        );
      }
    }
    return items;
  }

  static String _slug(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }
}

class _EventType {
  final String name;
  final String subtitle;
  final String tag;
  final String fee;
  final int durationDays;

  const _EventType(this.name, this.subtitle, this.tag, this.fee, this.durationDays);
}

const _eventTypes = [
  _EventType('City Open 2026', 'нээлттэй хотын аварга', 'Open', '50,000 MNT', 2),
  _EventType('University Cup', 'оюутны лигийн тэмцээн', 'University', '30,000 MNT', 1),
  _EventType('Youth Championship', 'өсвөрийн аварга шалгаруулах', 'Youth', 'Үнэгүй', 2),
  _EventType('Corporate League', 'байгууллагын лиг', 'Corporate', '80,000 MNT', 3),
  _EventType('National Series', 'үндэсний чансааны цуврал', 'National', '60,000 MNT', 2),
];

class _CategoryConfig {
  final String shortName;
  final String titlePrefix;
  final String organizer;
  final String scope;
  final String participationType;
  final int baseLimit;
  final int limitStep;
  final List<String> images;
  final List<String> locations;
  final List<String> prizes;
  final List<String> ageGroups;
  final String contactName;
  final String contactPhone;
  final String contactEmail;

  const _CategoryConfig({
    required this.shortName,
    required this.titlePrefix,
    required this.organizer,
    required this.scope,
    required this.participationType,
    required this.baseLimit,
    required this.limitStep,
    required this.images,
    required this.locations,
    required this.prizes,
    required this.ageGroups,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
  });
}

String _imageUrl(String keywords, int lock) {
  return 'https://loremflickr.com/1200/800/$keywords/all?lock=$lock';
}

List<String> _imageSet(String keywords, int baseLock) {
  return List.generate(5, (index) => _imageUrl(keywords, baseLock + index));
}

final _configs = {
  'Football': _CategoryConfig(
    shortName: 'Football',
    titlePrefix: 'Football',
    organizer: 'Mongolian Football Development Association',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Багийн',
    baseLimit: 16,
    limitStep: 4,
    images: _imageSet('football,soccer,stadium', 1000),
    locations: ['MFF Football Centre', 'National Sports Stadium', 'Erdenet Stadium'],
    prizes: ['5,000,000 MNT + trophy', '3,000,000 MNT + medals', 'Training kit package', '6,000,000 MNT league fund', 'National ranking points'],
    ageGroups: ['18+', '18+', '16-18', '18+', 'Бүх насны'],
    contactName: 'Enkhbold Bat',
    contactPhone: '+976 9900-1101',
    contactEmail: 'football@competition.example.com',
  ),
  'Basketball': _CategoryConfig(
    shortName: 'Basketball',
    titlePrefix: 'Basketball',
    organizer: 'Ulaanbaatar Basketball League',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Багийн',
    baseLimit: 12,
    limitStep: 4,
    images: _imageSet('basketball,court,player', 1100),
    locations: ['UG Arena', 'Central Sports Palace', 'Mongolian Basketball Hall'],
    prizes: ['4,000,000 MNT prize pool', '2,500,000 MNT + MVP award', 'Scholarship vouchers', '5,000,000 MNT league pool', 'Elite series qualification'],
    ageGroups: ['18+', '18+', '16-18', '21+', 'Бүх насны'],
    contactName: 'Anu Munkh',
    contactPhone: '+976 9900-1102',
    contactEmail: 'basketball@competition.example.com',
  ),
  'Volleyball': _CategoryConfig(
    shortName: 'Volleyball',
    titlePrefix: 'Volleyball',
    organizer: 'Mongolian Volleyball Union',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Багийн',
    baseLimit: 10,
    limitStep: 3,
    images: _imageSet('volleyball,beach,court', 1200),
    locations: ['Buyant-Ukhaa Sports Complex', 'Steppe Arena Training Hall', 'Darkhan Sports Hall'],
    prizes: ['3,500,000 MNT prize pool', '2,000,000 MNT + medals', 'Youth development grants', '4,500,000 MNT league pool', 'National league invitation'],
    ageGroups: ['18+', '18+', '16-18', '18+', 'Бүх насны'],
    contactName: 'Tsolmon Erdene',
    contactPhone: '+976 9900-1103',
    contactEmail: 'volleyball@competition.example.com',
  ),
  'Tennis': _CategoryConfig(
    shortName: 'Tennis',
    titlePrefix: 'Tennis',
    organizer: 'Mongolian Tennis Academy',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 32,
    limitStep: 8,
    images: _imageSet('tennis,court,racket', 1300),
    locations: ['National Tennis Centre', 'River Garden Tennis Courts', 'Khan-Uul Tennis Club'],
    prizes: ['2,000,000 MNT + trophy', '1,500,000 MNT', 'Junior academy vouchers', '3,000,000 MNT corporate pool', 'Ranking points + sponsor package'],
    ageGroups: ['18+', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Nomin Altan',
    contactPhone: '+976 9900-1104',
    contactEmail: 'tennis@competition.example.com',
  ),
  'Running': _CategoryConfig(
    shortName: 'Running',
    titlePrefix: 'Running',
    organizer: 'Steppe Runners Club',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 120,
    limitStep: 30,
    images: _imageSet('running,runner,track', 1400),
    locations: ['National Park Route', 'Sukhbaatar Square Start Line', 'Bogd Khan Mountain Trail'],
    prizes: ['3,000,000 MNT total purse', '1,800,000 MNT + finisher medals', 'Youth sports grants', 'Corporate team trophy', 'National ranking points'],
    ageGroups: ['18+', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Temuulen Gan',
    contactPhone: '+976 9900-1105',
    contactEmail: 'running@competition.example.com',
  ),
  'Swimming': _CategoryConfig(
    shortName: 'Swimming',
    titlePrefix: 'Swimming',
    organizer: 'Mongolian Aquatics Federation',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 48,
    limitStep: 12,
    images: _imageSet('swimming,pool,swimmer', 1500),
    locations: ['Central Swimming Pool', 'Bayangol Aquatic Centre', 'Orkhon Olympic Pool'],
    prizes: ['2,500,000 MNT prize pool', '1,800,000 MNT + medals', 'Junior training package', 'Club relay trophy', 'National ranking points'],
    ageGroups: ['18+', '18+', '13-17', '18+', 'Бүх насны'],
    contactName: 'Saruul Bold',
    contactPhone: '+976 9900-1106',
    contactEmail: 'swimming@competition.example.com',
  ),
  'Martial Arts': _CategoryConfig(
    shortName: 'Martial Arts',
    titlePrefix: 'Martial Arts',
    organizer: 'National Martial Arts Centre',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 40,
    limitStep: 8,
    images: _imageSet('martial-arts,karate,judo', 1600),
    locations: ['National Martial Arts Hall', 'Judo Palace', 'Central Dojo'],
    prizes: ['3,000,000 MNT + belts', '2,000,000 MNT + medals', 'Youth camp scholarship', 'Team trophy + sponsor kit', 'National ranking points'],
    ageGroups: ['18+', '18+', '13-17', '18+', 'Бүх насны'],
    contactName: 'Bilegt Dorj',
    contactPhone: '+976 9900-1107',
    contactEmail: 'martialarts@competition.example.com',
  ),
  'Esports': _CategoryConfig(
    shortName: 'Esports',
    titlePrefix: 'Esports',
    organizer: 'Mongolian Esports Association',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Багийн',
    baseLimit: 32,
    limitStep: 8,
    images: _imageSet('esports,gaming,computer', 1700),
    locations: ['MESA Esports Arena', 'Shangri-La Gaming Hall', 'Online Qualifier Server'],
    prizes: ['8,000,000 MNT prize pool', '5,000,000 MNT + peripherals', 'Academy contracts', '10,000,000 MNT league pool', 'International qualifier slot'],
    ageGroups: ['16+', '18+', '13-17', '18+', 'Бүх насны'],
    contactName: 'Ariunaa Tech',
    contactPhone: '+976 9900-1108',
    contactEmail: 'esports@competition.example.com',
  ),
  'Table Tennis': _CategoryConfig(
    shortName: 'Table Tennis',
    titlePrefix: 'Table Tennis',
    organizer: 'Table Tennis Development Club',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 48,
    limitStep: 8,
    images: _imageSet('table-tennis,ping-pong', 1800),
    locations: ['Table Tennis National Hall', 'Ikh Zasag Sports Centre', 'Darkhan Table Tennis Club'],
    prizes: ['1,800,000 MNT prize pool', '1,200,000 MNT + medals', 'Junior equipment grants', 'Corporate doubles trophy', 'Ranking points'],
    ageGroups: ['18+', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Munkh-Erdene Ts',
    contactPhone: '+976 9900-1109',
    contactEmail: 'tabletennis@competition.example.com',
  ),
  'Chess': _CategoryConfig(
    shortName: 'Chess',
    titlePrefix: 'Chess',
    organizer: 'Mongolian Chess Federation',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 64,
    limitStep: 16,
    images: _imageSet('chess,board,tournament', 1900),
    locations: ['Mongolian Chess Palace', 'National Library Hall', 'Online Chess Arena'],
    prizes: ['2,500,000 MNT + trophy', '1,500,000 MNT + rating awards', 'Junior masterclass package', 'Corporate chess shield', 'FIDE-style ranking points'],
    ageGroups: ['Бүх насны', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Khulan Master',
    contactPhone: '+976 9900-1110',
    contactEmail: 'chess@competition.example.com',
  ),
  'Badminton': _CategoryConfig(
    shortName: 'Badminton',
    titlePrefix: 'Badminton',
    organizer: 'Ulaanbaatar Badminton Club',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 40,
    limitStep: 8,
    images: _imageSet('badminton,shuttlecock,court', 2000),
    locations: ['Badminton Pro Hall', 'Central Sports Palace', 'Khan-Uul Shuttle Hall'],
    prizes: ['1,800,000 MNT prize pool', '1,200,000 MNT + medals', 'Junior gear support', 'Corporate doubles cup', 'National ranking points'],
    ageGroups: ['18+', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Oyun Shuttle',
    contactPhone: '+976 9900-1111',
    contactEmail: 'badminton@competition.example.com',
  ),
  'Cycling': _CategoryConfig(
    shortName: 'Cycling',
    titlePrefix: 'Cycling',
    organizer: 'Mongolian Cycling Association',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 80,
    limitStep: 20,
    images: _imageSet('cycling,bicycle,race', 2100),
    locations: ['Terelj Road Circuit', 'National Park Cycling Route', 'Khui Doloon Khudag Route'],
    prizes: ['4,000,000 MNT prize pool', '2,500,000 MNT + gear', 'Youth bike grants', 'Corporate team jersey cup', 'National ranking points'],
    ageGroups: ['18+', '18+', '16-18', '21+', 'Бүх насны'],
    contactName: 'Batbayar Cycle',
    contactPhone: '+976 9900-1112',
    contactEmail: 'cycling@competition.example.com',
  ),
  'Athletics': _CategoryConfig(
    shortName: 'Athletics',
    titlePrefix: 'Athletics',
    organizer: 'National Athletics Federation',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 100,
    limitStep: 20,
    images: _imageSet('athletics,track-field,stadium', 2200),
    locations: ['National Athletics Stadium', 'Nalaikh Track Centre', 'Erdenet Athletics Field'],
    prizes: ['3,500,000 MNT prize pool', '2,000,000 MNT + medals', 'Youth development grants', 'Corporate relay trophy', 'National ranking points'],
    ageGroups: ['18+', '18+', '13-17', '21+', 'Бүх насны'],
    contactName: 'Enkhjin Track',
    contactPhone: '+976 9900-1113',
    contactEmail: 'athletics@competition.example.com',
  ),
  'MMA': _CategoryConfig(
    shortName: 'MMA',
    titlePrefix: 'MMA',
    organizer: 'Mongolian MMA League',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 28,
    limitStep: 6,
    images: _imageSet('mma,fight,cage', 2300),
    locations: ['MMA Pro Cage Arena', 'Central Combat Hall', 'Steppe Fight Centre'],
    prizes: ['6,000,000 MNT fight purse', '4,000,000 MNT + title belt', 'Prospect contract package', 'Corporate fight night purse', 'Pro ranking points'],
    ageGroups: ['18+', '18+', '18+', '21+', '18+'],
    contactName: 'Sukh Fight',
    contactPhone: '+976 9900-1114',
    contactEmail: 'mma@competition.example.com',
  ),
  'Wrestling': _CategoryConfig(
    shortName: 'Wrestling',
    titlePrefix: 'Wrestling',
    organizer: 'Mongolian Wrestling Academy',
    scope: 'Үндэсний хэмжээний',
    participationType: 'Ганцаараа',
    baseLimit: 48,
    limitStep: 8,
    images: _imageSet('wrestling,grappling,mat', 2400),
    locations: ['Wrestling Palace', 'National Sports Palace', 'Bulgan Wrestling Hall'],
    prizes: ['5,000,000 MNT prize pool', '3,000,000 MNT + medals', 'Youth training grants', 'Corporate team trophy', 'National ranking points'],
    ageGroups: ['18+', '18+', '16-18', '21+', 'Бүх насны'],
    contactName: 'Ganbold Bukh',
    contactPhone: '+976 9900-1115',
    contactEmail: 'wrestling@competition.example.com',
  ),
};
