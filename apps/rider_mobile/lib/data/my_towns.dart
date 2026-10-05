/// Malaysian towns for Find Jobs "Change location" (D-75). Bundled, so no
/// geocoding service is called (Mapbox is on hold). Coordinates are town
/// centres; they only set the search point for distance.
class MyTown {
  const MyTown(this.name, this.state, this.latitude, this.longitude);
  final String name, state;
  final double latitude, longitude;
}

const myTowns = <MyTown>[
  // Kuala Lumpur & Putrajaya
  MyTown('Kuala Lumpur', 'Kuala Lumpur', 3.1390, 101.6869),
  MyTown('Bangsar', 'Kuala Lumpur', 3.1290, 101.6790),
  MyTown('Cheras', 'Kuala Lumpur', 3.1060, 101.7260),
  MyTown('Kepong', 'Kuala Lumpur', 3.2100, 101.6370),
  MyTown('Setapak', 'Kuala Lumpur', 3.1980, 101.7180),
  MyTown('Wangsa Maju', 'Kuala Lumpur', 3.2050, 101.7370),
  MyTown('Putrajaya', 'Putrajaya', 2.9264, 101.6964),
  // Selangor
  MyTown('Petaling Jaya', 'Selangor', 3.1073, 101.6067),
  MyTown('Subang Jaya', 'Selangor', 3.0567, 101.5851),
  MyTown('Shah Alam', 'Selangor', 3.0733, 101.5185),
  MyTown('Klang', 'Selangor', 3.0449, 101.4456),
  MyTown('Puchong', 'Selangor', 3.0250, 101.6170),
  MyTown('Cyberjaya', 'Selangor', 2.9213, 101.6559),
  MyTown('Kajang', 'Selangor', 2.9927, 101.7909),
  MyTown('Bangi', 'Selangor', 2.9600, 101.7660),
  MyTown('Seri Kembangan', 'Selangor', 3.0210, 101.7080),
  MyTown('Ampang', 'Selangor', 3.1500, 101.7600),
  MyTown('Selayang', 'Selangor', 3.2510, 101.6500),
  MyTown('Gombak', 'Selangor', 3.2530, 101.7000),
  MyTown('Rawang', 'Selangor', 3.3213, 101.5767),
  MyTown('Sepang', 'Selangor', 2.6900, 101.7500),
  MyTown('Banting', 'Selangor', 2.8100, 101.5000),
  MyTown('Kuala Selangor', 'Selangor', 3.3400, 101.2500),
  // Negeri Sembilan & Melaka
  MyTown('Seremban', 'Negeri Sembilan', 2.7259, 101.9424),
  MyTown('Nilai', 'Negeri Sembilan', 2.8150, 101.7980),
  MyTown('Port Dickson', 'Negeri Sembilan', 2.5228, 101.7959),
  MyTown('Melaka', 'Melaka', 2.1896, 102.2501),
  // Johor
  MyTown('Johor Bahru', 'Johor', 1.4927, 103.7414),
  MyTown('Iskandar Puteri', 'Johor', 1.4180, 103.6420),
  MyTown('Skudai', 'Johor', 1.5340, 103.6580),
  MyTown('Kulai', 'Johor', 1.6560, 103.6000),
  MyTown('Batu Pahat', 'Johor', 1.8548, 102.9325),
  MyTown('Muar', 'Johor', 2.0442, 102.5689),
  MyTown('Kluang', 'Johor', 2.0251, 103.3328),
  MyTown('Segamat', 'Johor', 2.5148, 102.8158),
  // Perak
  MyTown('Ipoh', 'Perak', 4.5975, 101.0901),
  MyTown('Taiping', 'Perak', 4.8500, 100.7333),
  MyTown('Teluk Intan', 'Perak', 4.0259, 101.0213),
  MyTown('Sitiawan', 'Perak', 4.2167, 100.7000),
  // Penang, Kedah, Perlis
  MyTown('George Town', 'Pulau Pinang', 5.4141, 100.3288),
  MyTown('Bayan Lepas', 'Pulau Pinang', 5.2945, 100.2593),
  MyTown('Butterworth', 'Pulau Pinang', 5.3991, 100.3638),
  MyTown('Bukit Mertajam', 'Pulau Pinang', 5.3633, 100.4667),
  MyTown('Alor Setar', 'Kedah', 6.1210, 100.3678),
  MyTown('Sungai Petani', 'Kedah', 5.6470, 100.4877),
  MyTown('Kulim', 'Kedah', 5.3650, 100.5617),
  MyTown('Langkawi', 'Kedah', 6.3500, 99.8000),
  MyTown('Kangar', 'Perlis', 6.4414, 100.1986),
  // East coast
  MyTown('Kota Bharu', 'Kelantan', 6.1254, 102.2381),
  MyTown('Kuala Terengganu', 'Terengganu', 5.3296, 103.1370),
  MyTown('Kemaman', 'Terengganu', 4.2333, 103.4167),
  MyTown('Kuantan', 'Pahang', 3.8077, 103.3260),
  MyTown('Temerloh', 'Pahang', 3.4500, 102.4167),
  MyTown('Bentong', 'Pahang', 3.5200, 101.9100),
  // Sabah, Sarawak, Labuan
  MyTown('Kota Kinabalu', 'Sabah', 5.9804, 116.0735),
  MyTown('Sandakan', 'Sabah', 5.8402, 118.1179),
  MyTown('Tawau', 'Sabah', 4.2448, 117.8912),
  MyTown('Kuching', 'Sarawak', 1.5535, 110.3593),
  MyTown('Sibu', 'Sarawak', 2.2870, 111.8305),
  MyTown('Bintulu', 'Sarawak', 3.1700, 113.0300),
  MyTown('Miri', 'Sarawak', 4.3995, 113.9914),
  MyTown('Labuan', 'Labuan', 5.2831, 115.2308),
];
