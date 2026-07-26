import 'package:flutter_bloc/flutter_bloc.dart';

class NavCubit extends Cubit<int> {
  NavCubit() : super(0);

  void selectTab(int index) {
    if (index >= 0 && index <= 3) {
      emit(index);
    }
  }
}
