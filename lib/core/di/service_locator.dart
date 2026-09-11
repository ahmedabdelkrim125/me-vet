// import 'package:get_it/get_it.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../features/home/data/home_repository.dart';
// import '../../features/home/presentation/cubit/home_cubit.dart';

// import '../../features/customer_account/data/datasources/customer_account_remote_data_source.dart';
// import '../../features/customer_account/data/repositories/customer_account_repository_impl.dart';
// import '../../features/customer_account/domain/repositories/customer_account_repository.dart';
// import '../../features/customer_account/domain/usecases/create_sales_return.dart';
// import '../../features/customer_account/domain/usecases/get_customer_ledger.dart';
// import '../../features/customer_account/domain/usecases/record_customer_payment.dart';
// import '../../features/customer_account/domain/usecases/record_customer_account_payment.dart';
// import '../../features/customer_account/domain/usecases/get_invoice_returned_quantities.dart';
// import '../../features/customer_account/presentation/cubit/customer_account_cubit.dart';

// import '../../features/inventory/data/products_repository.dart';
// import '../../features/inventory/data/datasources/vehicle_stock_remote_data_source.dart';
// import '../../features/inventory/domain/repositories/vehicle_stock_repository.dart';
// import '../../features/inventory/domain/repositories/vehicle_stock_repository_impl.dart';
// import '../../features/inventory/domain/usecases/deduct_vehicle_stock.dart';
// import '../../features/inventory/domain/usecases/create_vehicle_for_current_rep.dart';
// import '../../features/inventory/domain/usecases/get_stock_movements.dart';
// import '../../features/inventory/domain/usecases/get_vehicle_stock.dart';
// import '../../features/inventory/domain/usecases/get_vehicles.dart';
// import '../../features/inventory/domain/usecases/load_vehicle_stock.dart';
// import '../../features/inventory/domain/usecases/return_vehicle_stock.dart';
// import '../../features/inventory/presentation/cubit/vehicle_stock_cubit.dart';

// final sl = GetIt.instance;

// void setupServiceLocator() {
//   sl.registerLazySingleton<HomeRepository>(
//     () => HomeRepository(Supabase.instance.client),
//   );

//   sl.registerFactory<HomeCubit>(
//     () => HomeCubit(sl<HomeRepository>()),
//   );

//   sl.registerLazySingleton<CustomerAccountRemoteDataSource>(
//     () => CustomerAccountRemoteDataSource(Supabase.instance.client),
//   );

//   sl.registerLazySingleton<CustomerAccountRepository>(
//     () => CustomerAccountRepositoryImpl(sl()),
//   );

//   sl.registerFactory<GetCustomerLedger>(
//     () => GetCustomerLedger(sl()),
//   );

//   sl.registerFactory<RecordCustomerPayment>(
//     () => RecordCustomerPayment(sl()),
//   );

//   sl.registerFactory<RecordCustomerAccountPayment>(
//     () => RecordCustomerAccountPayment(sl()),
//   );

//   sl.registerFactory<CreateSalesReturn>(
//     () => CreateSalesReturn(sl()),
//   );

//   sl.registerFactory<GetInvoiceReturnedQuantities>(
//     () => GetInvoiceReturnedQuantities(sl()),
//   );

//   sl.registerFactory<CustomerAccountCubit>(
//     () => CustomerAccountCubit(
//       getCustomerLedger: sl(),
//       recordCustomerAccountPayment: sl(),
//       createSalesReturn: sl(),
//       getInvoiceReturnedQuantities: sl(),
//     ),
//   );

//   sl.registerLazySingleton<ProductsRepository>(
//     () => ProductsRepository.instance,
//   );

//   sl.registerLazySingleton<VehicleStockRemoteDataSource>(
//     () => VehicleStockRemoteDataSource(Supabase.instance.client),
//   );

//   sl.registerLazySingleton<VehicleStockRepository>(
//     () => VehicleStockRepositoryImpl(
//       remoteDataSource: sl(),
//     ),
//   );

//   sl.registerFactory<GetVehicles>(
//     () => GetVehicles(sl()),
//   );

//   sl.registerFactory<CreateVehicleForCurrentRep>(
//     () => CreateVehicleForCurrentRep(sl()),
//   );

//   sl.registerFactory<GetVehicleStock>(
//     () => GetVehicleStock(sl()),
//   );

//   sl.registerFactory<GetStockMovements>(
//     () => GetStockMovements(sl()),
//   );

//   sl.registerFactory<LoadVehicleStock>(
//     () => LoadVehicleStock(sl()),
//   );

//   sl.registerFactory<DeductVehicleStock>(
//     () => DeductVehicleStock(sl()),
//   );

//   sl.registerFactory<ReturnVehicleStock>(
//     () => ReturnVehicleStock(sl()),
//   );

//   sl.registerFactory<VehicleStockCubit>(
//     () => VehicleStockCubit(
//       getVehicles: sl(),
//       getVehicleStock: sl(),
//       getStockMovements: sl(),
//       loadVehicleStock: sl(),
//       deductVehicleStock: sl(),
//       returnVehicleStock: sl(),
//       createVehicleForCurrentRep: sl(),
//     ),
//   );
// }
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';

import '../../features/customer_account/data/datasources/customer_account_remote_data_source.dart';
import '../../features/customer_account/data/repositories/customer_account_repository_impl.dart';
import '../../features/customer_account/domain/repositories/customer_account_repository.dart';
import '../../features/customer_account/domain/usecases/create_sales_return.dart';
import '../../features/customer_account/domain/usecases/get_customer_ledger.dart';
import '../../features/customer_account/domain/usecases/record_customer_payment.dart';
import '../../features/customer_account/domain/usecases/record_customer_account_payment.dart';
import '../../features/customer_account/domain/usecases/get_invoice_returned_quantities.dart';
import '../../features/customer_account/presentation/cubit/customer_account_cubit.dart';

import '../../features/inventory/data/products_repository.dart';
import '../../features/inventory/data/datasources/vehicle_stock_remote_data_source.dart';
import '../../features/inventory/domain/repositories/vehicle_stock_repository.dart';
// Fixed the import path mapping to data layer implementation
import '../../features/inventory/data/repositories/vehicle_stock_repository_impl.dart'; 
import '../../features/inventory/domain/usecases/deduct_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/create_vehicle_for_current_rep.dart';
import '../../features/inventory/domain/usecases/get_stock_movements.dart';
import '../../features/inventory/domain/usecases/get_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/get_vehicles.dart';
import '../../features/inventory/domain/usecases/load_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/return_vehicle_stock.dart';
import '../../features/inventory/presentation/cubit/vehicle_stock_cubit.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepository(Supabase.instance.client),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<CustomerAccountRemoteDataSource>(
    () => CustomerAccountRemoteDataSource(Supabase.instance.client),
  );

  sl.registerLazySingleton<CustomerAccountRepository>(
    () => CustomerAccountRepositoryImpl(sl()),
  );

  sl.registerFactory<GetCustomerLedger>(
    () => GetCustomerLedger(sl()),
  );

  sl.registerFactory<RecordCustomerPayment>(
    () => RecordCustomerPayment(sl()),
  );

  sl.registerFactory<RecordCustomerAccountPayment>(
    () => RecordCustomerAccountPayment(sl()),
  );

  sl.registerFactory<CreateSalesReturn>(
    () => CreateSalesReturn(sl()),
  );

  sl.registerFactory<GetInvoiceReturnedQuantities>(
    () => GetInvoiceReturnedQuantities(sl()),
  );

  sl.registerFactory<CustomerAccountCubit>(
    () => CustomerAccountCubit(
      getCustomerLedger: sl(),
      recordCustomerAccountPayment: sl(),
      createSalesReturn: sl(),
      getInvoiceReturnedQuantities: sl(),
    ),
  );

  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepository.instance,
  );

  sl.registerLazySingleton<VehicleStockRemoteDataSource>(
    () => VehicleStockRemoteDataSource(Supabase.instance.client),
  );

  sl.registerLazySingleton<VehicleStockRepository>(
    () => VehicleStockRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerFactory<GetVehicles>(
    () => GetVehicles(sl()),
  );

  sl.registerFactory<CreateVehicleForCurrentRep>(
    () => CreateVehicleForCurrentRep(sl()),
  );

  sl.registerFactory<GetVehicleStock>(
    () => GetVehicleStock(sl()),
  );

  sl.registerFactory<GetStockMovements>(
    () => GetStockMovements(sl()),
  );

  sl.registerFactory<LoadVehicleStock>(
    () => LoadVehicleStock(sl()),
  );

  sl.registerFactory<DeductVehicleStock>(
    () => DeductVehicleStock(sl()),
  );

  sl.registerFactory<ReturnVehicleStock>(
    () => ReturnVehicleStock(sl()),
  );

  sl.registerFactory<VehicleStockCubit>(
    () => VehicleStockCubit(
      getVehicles: sl(),
      getVehicleStock: sl(),
      getStockMovements: sl(),
      loadVehicleStock: sl(),
      deductVehicleStock: sl(),
      returnVehicleStock: sl(),
      createVehicleForCurrentRep: sl(),
    ),
  );
}