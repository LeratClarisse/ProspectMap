import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../domain/usecases/get_roads_usecase.dart';
import '../domain/usecases/search_roads_usecase.dart';
import '../domain/usecases/save_ride_usecase.dart';
import '../domain/usecases/delete_ride_usecase.dart';
import '../domain/usecases/get_location_usecase.dart';
import '../domain/usecases/calculate_road_distance_usecase.dart';
import 'pages/home/cubit/home_cubit.dart';
import 'pages/home/home_page.dart';

class App extends StatelessWidget {
  final GetRoadsUseCase getRoadsUseCase;
  final SearchRoadsUseCase searchRoadsUseCase;
  final SaveRideUseCase saveRideUseCase;
  final DeleteRideUseCase deleteRideUseCase;
  final GetLocationUseCase getLocationUseCase;
  final CalculateRoadDistanceUseCase calculateRoadDistanceUseCase;

  const App({
    Key? key,
    required this.getRoadsUseCase,
    required this.searchRoadsUseCase,
    required this.saveRideUseCase,
    required this.deleteRideUseCase,
    required this.getLocationUseCase,
    required this.calculateRoadDistanceUseCase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        getRoadsUseCase: getRoadsUseCase,
        searchRoadsUseCase: searchRoadsUseCase,
        saveRideUseCase: saveRideUseCase,
        deleteRideUseCase: deleteRideUseCase,
        getLocationUseCase: getLocationUseCase,
        calculateRoadDistanceUseCase: calculateRoadDistanceUseCase,
      ),
      child: MaterialApp(
        title: 'Road Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system, // You can integrate with settings later
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
