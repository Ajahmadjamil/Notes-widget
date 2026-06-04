//
//
// import 'package:flutter/material.dart';
//
// class CustomConfirmationDialog extends StatelessWidget {
//   final String? title;
//   final String message;
//   final VoidCallback onConfirm;
//   final VoidCallback? onCancel;
//   final bool isCloseable;
//
//   const CustomConfirmationDialog({
//     super.key,
//     this.title,
//     required this.message,
//     required this.onConfirm,
//     this.onCancel,
//     this.isCloseable = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => isCloseable,
//       child: Dialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Flexible(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       title != null
//                           ? Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 24),
//                                   child: Text(
//                                     title!,
//                                     style: getMediumStyle(
//                                       color: AppColors.textColor,
//                                       fontSize: 24,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 20),
//                               ],
//                             )
//                           : Text(''),
//                       Lottie.asset(
//                         Assets.imagesLogOut,
//                         width: 150,
//                         height: 150,
//                         fit: BoxFit.contain,
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         message,
//                         textAlign: TextAlign.center,
//                         style: getRegularStyle(color: AppColors.textColor),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               if (isCloseable)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     InkWell(
//                       onTap: onCancel ?? () => Navigator.of(context).pop(),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 16),
//                         height: 48,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                               width: 1, color: AppColors.primaryColor),
//                         ),
//                         child: Center(
//                           child: Text(
//                             "Not Now",
//                             style: getMediumStyle(
//                               fontSize: 16,
//                               color: AppColors.primaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     InkWell(
//                       onTap: onConfirm,
//                       child: Container(
//                         width: 120,
//                         height: 48,
//                         decoration: BoxDecoration(
//                           color: AppColors.primaryColor,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Text(
//                             "Yes",
//                             style: getMediumStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               else
//                 InkWell(
//                   onTap: onConfirm,
//                   child: Container(
//                     width: double.infinity,
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryColor.withOpacity(.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: Text(
//                         "Dismiss",
//                         style: getMediumStyle(
//                             fontSize: 16, color: AppColors.primaryColor),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
