import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/common/extentions/contenxt_x.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/core/presentation/loading.dart';
import 'package:thesis/feature/instruction/presentation/cubit/instruction_cubit.dart';
import 'package:thesis/feature/instruction/presentation/widget/list.dart';
import 'package:thesis/feature/instruction/presentation/widget/note.dart';
import 'package:thesis/feature/instruction/presentation/widget/widget.dart';
import 'package:thesis/feature/instruction/presentation/page/student_detail_screen.dart';
import 'package:thesis/shared/widgets/appbar.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';

import '../../../../common/contranst/colors.dart';
import '../../domain/status_enum.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.bg,
      appBar: AppAppBar(
        title: 'Thông tin phòng thi',
        rightBtns: [Icon(Icons.search, size: 24, color: UIColors.white)],
      ),
      body: BlocProvider(
        create: (context) => InstructionCubit()
          ..fetchDetail(id)
          ..fetchStudents(),
        child: BlocBuilder<InstructionCubit, InstructionState>(
          builder: (context, state) {
            if (state.status.isLoading) {
              debugPrint(state.detail.toString());
              return const Center(child: LoadingIndicator());
            } else if (state.detail == null) {
              return Center(child: AppText.semiBold("no data"));
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.gap,
                  AppText.regular(
                    'Thông tin',
                    fontSize: 14,
                    color: UIColors.gray,
                  ),
                  16.gap,
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: UIColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: UIColors.lightGray),
                    ),
                    child: Column(
                      children: [
                        InstructionWidget(
                          title: 'Mã học phần',
                          value: state.detail?.sourceCode ?? '',
                        ),
                        12.gap,
                        InstructionWidget(
                          title: 'Môn thi',
                          value: state.detail?.subjectName ?? '',
                        ),
                        12.gap,
                        InstructionWidget(
                          title: 'Phòng thi',
                          value: state.detail?.classroom ?? '',
                        ),
                        12.gap,
                        InstructionWidget(
                          title: 'Tiết',
                          value: state.detail?.period ?? '',
                        ),
                        12.gap,
                        Row(
                          children: [
                            AppText.semiBold(
                              'Sỉ số sinh viên',
                              fontSize: 14,
                              color: UIColors.white,
                            ),

                            Spacer(),
                            AppText.bold(
                              '${state.detail?.present}/',
                              color: UIColors.yellow,
                            ),
                            AppText.bold(
                              '${(state.students ?? []).length}',
                              color: UIColors.green,
                            ),
                          ],
                        ),
                        12.gap,
                        InstructionWidget(
                          title: 'Cơ sở',
                          value: '${state.detail?.branch}',
                        ),
                      ],
                    ),
                  ),
                  24.gap,
                  Row(
                    children: [
                      AppText.regular(
                        'Danh sách',
                        fontSize: 14,
                        color: UIColors.gray,
                      ),
                      Spacer(),
                      InfoExamWidget(),
                    ],
                  ),
                  16.gap,
                  Expanded(
                    child: ListView.separated(
                      primary: false,
                      shrinkWrap: false,
                      cacheExtent: 200,
                      itemBuilder: (context, index) {
                        return AppButton.widget(
                          child: ListStudentWidget(
                            name: (state.students ?? [])[index].name ?? '-',
                            status:
                                (state.students ?? [])[index].status ??
                                StatusEnum.present,
                          ),
                          onTap: () {
                            context.showFullScreenBottomSheet(
                              child: StudentDetailScreen(
                                student: (state.students ?? [])[index],
                              ),
                            );
                          },
                        );
                      },
                      itemCount: (state.students ?? []).length,
                      separatorBuilder: (context, index) {
                        return 16.gap;
                      },
                    ),
                  ),
                  16.gap,
                  AppButton.fill(
                    onTap: () =>
                        context.read<InstructionCubit>().scanBarcode(context),
                    titleWidget: AppText.semiBold(
                      'Xác thực sinh viên',
                      fontSize: 14,
                      color: UIColors.white,
                    ),
                  ),
                  context.paddingBottomForButton.gap,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// _verifyStudent(context)
