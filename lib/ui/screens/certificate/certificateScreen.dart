import 'package:eschool/cubits/certificatesCubit.dart';
import 'package:eschool/data/repositories/certificateRepository.dart';
import 'package:eschool/ui/screens/certificate/certificateListContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class CertificateScreen extends StatelessWidget {
  final int? childId;

  const CertificateScreen({Key? key, this.childId}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<CertificatesCubit>(
      create: (_) => CertificatesCubit(CertificateRepository()),
      child: CertificateScreen(
        childId: Get.arguments as int?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CertificateListContainer(childId: childId),
    );
  }
}
