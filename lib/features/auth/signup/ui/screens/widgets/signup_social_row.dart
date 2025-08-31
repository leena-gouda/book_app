import 'package:book_app/core/theme/app_colors.dart';
import 'package:book_app/core/utils/extensions/navigation_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/routing/routes.dart';
import '../../../../../../core/widgets/custom_login_with_google.dart';
import '../../../../../../core/widgets/signup_login_text.dart';

class SignUpSocialRow extends StatelessWidget {
  const SignUpSocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        CustomLoginWithGoogle(imagePath: AppAssets.googleIcon),
        const SizedBox(height: 22),

      ],
    );
  }
}