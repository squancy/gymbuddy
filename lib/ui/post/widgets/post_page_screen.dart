import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as datepicker;
import 'package:intl/intl.dart';
import 'package:moye/moye.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/ui/post/view_models/post_page_view_model.dart';
import 'package:gym_buddy/ui/core/common_ui.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class PostPage extends StatefulWidget {
  const PostPage({
    required this.viewModel,
    required this.postPageActs,
    required this.postPageGyms,
    super.key
  });

  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;
  final PostPageViewModel viewModel;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    final uploadPhoto = BottomSheetContent(
      selectFromSource: widget.viewModel.selectFromSource
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
        )
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (BuildContext context, Widget? child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 'Find a gym buddy' text
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                        child: Text(
                          PostPageConsts.appBarText, // 'Find a gym buddy'
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).withGradientOverlay(gradient: LinearGradient(colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                          Theme.of(context).colorScheme.primary,
                        ])),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              key: const Key('textField'),
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: PostPageConsts.textBarText, // 'Looking for a buddy?'
                                hintStyle: TextStyle(
                                  color: Colors.grey
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none
                              ),
                              maxLines: null,
                              controller: widget.viewModel.controller,
                            ),
                          ],
                        ),
                      ),
                      // Daytype scrollable dropdown menu
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: CustomDropdown<String>(
                          key: const Key('activityField'),
                          hintText: PostPageConsts.dayTypeText, // 'What are you going to do?'
                          items: widget.postPageActs,
                          onChanged: (p0) {
                            widget.viewModel.dayType = p0;
                          },
                          excludeSelected: false,
                          overlayHeight: 350,
                          decoration: CustomDropdownDecoration(
                            closedFillColor: Colors.black,
                            expandedFillColor: Colors.black,                      
                            listItemDecoration: ListItemDecoration(
                              highlightColor:  const Color.fromARGB(255, 23, 23, 23),
                              selectedColor: const Color.fromARGB(255, 23, 23, 23),
                              splashColor:  const Color.fromARGB(255, 23, 23, 23)
                            ),
                          ),
                        ),
                      ),
                      // Gym scrollable dropdown menu
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: CustomDropdown<Map<String, dynamic>>.search(
                          key: const Key('gymField'),
                          hintText: PostPageConsts.gymTypeText, // 'Which gym are you going to?'
                          items: widget.postPageGyms,
                          onChanged: (p0) {
                            widget.viewModel.gym = p0?.keys.toList()[0];
                          },
                          headerBuilder: (context, selectedItem, enabled) {
                            return Text(
                              selectedItem[selectedItem.keys.toList()[0]]['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500
                              ),);
                          },
                          overlayHeight: 350,
                          listItemBuilder: (context, item, isSelected, onItemSelect) {
                            String name = item[item.keys.toList()[0]]['name'];
                            String address = item[item.keys.toList()[0]]['address'];
                            return RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                                children: <TextSpan>[
                                  TextSpan(text: name),
                                  TextSpan(text: '\t|\t'),
                                  TextSpan(text: address, style: TextStyle(
                                    color: Colors.grey)
                                  ),
                                ],
                              ),
                            );
                          },
                          excludeSelected: false,
                          decoration: CustomDropdownDecoration(
                            closedFillColor: Colors.black,
                            expandedFillColor: Colors.black,
                            listItemDecoration: ListItemDecoration(
                              highlightColor:  const Color.fromARGB(255, 23, 23, 23),
                              selectedColor: const Color.fromARGB(255, 23, 23, 23),
                              splashColor:  const Color.fromARGB(255, 23, 23, 23)
                            ),
                            searchFieldDecoration: SearchFieldDecoration(
                              fillColor: Colors.black
                            )
                          ),
                        ),
                      ),
                      // Date and time picker
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                child: FilledButton.icon(
                                  key: const Key('timeField'),
                                  icon: Icon(
                                    Icons.date_range_rounded,
                                    size: 18,
                                    color: widget.viewModel.datetimeVal != null ?
                                      Colors.white :
                                      Colors.grey,
                                  ),
                                  onPressed: () {
                                    DateTime now = DateTime.now();
                                    datepicker.DatePicker.showDateTimePicker(
                                      context,
                                      theme: datepicker.DatePickerTheme(
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        doneStyle: TextStyle(color: Colors.white),
                                        cancelStyle: TextStyle(color: Colors.white),
                                        itemStyle: TextStyle(color: Colors.white)
                                      ),
                                      showTitleActions: true,
                                      minTime: now,
                                      onConfirm: (date) {
                                        widget.viewModel.datetime = date;
                                      },
                                      currentTime: DateTime.now(),
                                      locale: datepicker.LocaleType.en
                                    );
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(Colors.black),
                                    foregroundColor: widget.viewModel.datetimeVal != null ?
                                      WidgetStateProperty.all(Colors.white) :
                                      WidgetStateProperty.all(Colors.grey) 
                                  ),
                                  label: widget.viewModel.datetimeVal != null ?
                                    Text(DateFormat('MM-dd kk:mm')
                                      .format(widget.viewModel.datetimeVal as DateTime)) :
                                    Text(PostPageConsts.timeTypeText), 
                                ),
                              ),
                            ),
                            Expanded(
                              // Upload photos button
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: FilledButton.icon(
                                  key: const Key('uploadField'),
                                  onPressed: () {
                                    uploadPhoto.showOptions(context);
                                  },
                                  label: Text(PostPageConsts.photosUploadText), // 'Add photos'
                                  icon: Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 18,
                                    color: widget.viewModel.selectedImages.isNotEmpty ?
                                      Colors.white :
                                      Colors.grey,
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(Colors.black),
                                    foregroundColor: widget.viewModel.selectedImages.isNotEmpty ?
                                      WidgetStateProperty.all(Colors.white) :
                                      WidgetStateProperty.all(Colors.grey)
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      // Show selected images
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: helpers.HorizontalImageViewer(
                          showImages: widget.viewModel.showImages,
                          images: widget.viewModel.selectedImages,
                          isPost: true
                        )
                      ),
                      widget.viewModel.progress == null ? Padding( 
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: SizedBox(
                          height: 45,
                          child: helpers.ProgressBtn(
                            key: const Key('postBtn'),
                            onPressedFn: () {
                              return widget.viewModel.createNewPost(
                                images: widget.viewModel.selectedImages,
                                postText: widget.viewModel.controller.text,
                                dayType: widget.viewModel.dayTypeVal,
                                gymID: widget.viewModel.gymVal,
                                when: widget.viewModel.datetimeVal
                              );
                            },
                            child: Text(PostPageConsts.postButtonText), 
                          )
                        ),
                      ) : Container(),
                      widget.viewModel.progress != null ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: LinearGradientProgressBar(
                          value: widget.viewModel.progress!,
                          blurRadius: 10,
                          spreadRadius: 1,
                          borderRadius: BorderRadius.circular(56),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.tertiary,
                            ],
                          ),
                        ),
                      ) : Container(),
                      widget.viewModel.hasError ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                          child: Text(widget.viewModel.errorMsg),
                        )
                      ) : Container()
                    ]
                  ),
                )
              ],
            )
          );
        }
      )
    );
  }
}