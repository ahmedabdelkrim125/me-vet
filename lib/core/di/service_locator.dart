// import 'package:get_it/get_it.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../features/home/data/home_repository.dart';
// import '../../features/home/presentation/cubit/home_cubit.dart';

// final sl = GetIt.instance;

// void setupServiceLocator() {
//   sl.registerLazySingleton<HomeRepository>(
//     () => HomeRepository(Supabase.instance.client),
//   );

//   sl.registerFactory<HomeCubit>(
//     () => HomeCubit(sl<HomeRepository>()),
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
import '../../features/customer_account/presentation/cubit/customer_account_cubit.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepository(Supabase.instance.client),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<HomeRepository>()),
  );

  // --- Customer account feature ---
  sl.registerLazySingleton<CustomerAccountRemoteDataSource>(
    () => CustomerAccountRemoteDataSource(Supabase.instance.client),
  );

  sl.registerLazySingleton<CustomerAccountRepository>(
    () => CustomerAccountRepositoryImpl(sl()),
  );

  sl.registerFactory<GetCustomerLedger>(() => GetCustomerLedger(sl()));
  sl.registerFactory<RecordCustomerPayment>(() => RecordCustomerPayment(sl()));
  sl.registerFactory<CreateSalesReturn>(() => CreateSalesReturn(sl()));

  sl.registerFactory<CustomerAccountCubit>(
    () => CustomerAccountCubit(
      getCustomerLedger: sl(),
      recordCustomerPayment: sl(),
      createSalesReturn: sl(),
    ),
  );
}