import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:p_a_jewerly/components/bottom_bar_screen.dart';

class CustomerPaymentsScreen extends StatelessWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomBarScreen(
      body: Column(
      children: [
        SearchCustomerWidget()
      ],
    ), actionWidget: AddPayment(
      customer: 'Current Customer',
    ));
  }
}

class AddPayment extends StatelessWidget {
  const AddPayment({super.key, required this.customer});
  final String customer;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * .5,
      child: Form(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Text('Add new payment for: $customer'),
            SizedBox(height: 10,),
            _PaymentInput(label: 'Sale code'),
            SizedBox(height: 10,),
            _PaymentInput(label: 'Total amount'),
            SizedBox(height: 10,),
            OutlinedButton(onPressed: (){}, child: Icon(Icons.add))
          ],
        )
      )
    );
  }
}

class _PaymentInput extends StatelessWidget {
  const _PaymentInput({
    super.key, required this.label,
  });
  final String label;


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autocorrect: false,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

const List<String> list = <String>['Pedro Juarez', 'Jordan Smith', 'Kobe Bryant', 'Jordan Hall'];

class SearchCustomerWidget extends StatefulWidget {
  const SearchCustomerWidget({super.key});

  @override
  State<SearchCustomerWidget> createState() => _SearchCustomerWidgetState();
}

class _SearchCustomerWidgetState extends State<SearchCustomerWidget> {
  String dropdownValue = list.first;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5),
                child: CircleAvatar(
                  backgroundColor: Colors.black12,
                  radius: 20,
                  child: Icon(Icons.search)
                ),
              ),
              SizedBox(width: 10,),
              DropdownMenu<String>(
                width: size.width * .8,
                initialSelection: list.first,
                onSelected: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    dropdownValue = value!;
                    _index = list.indexOf(value) + 1;
                  });
                },
                dropdownMenuEntries: list.map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 50,),
          Container(
            width: size.width * .6,
            child: Center(
              child: Swiper(
                itemCount: _index,
                layout: SwiperLayout.STACK,
                itemWidth: size.width * .3,
                itemHeight: size.height * .4,
                itemBuilder: (_,index){
                  return GestureDetector(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: Offset(-5, 0)
                            ),
                          ]
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 10,),
                            CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person, size: 35),
                            ),
                            SizedBox(height: 10,),
                            Text('Name: $dropdownValue'),
                            SizedBox(height: 10,),
                            Text('Payment date: 00/00/0000'),
                            SizedBox(height: 10,),
                            Text('Sale code: 000000000$index'),
                            Expanded(child: Container()),
                            Text('Previous balance: 00.0'),
                            Text('Subsequent balance: 00.0'),
                            SizedBox(height: 10,),
                            OutlinedButton(onPressed: (){

                            }, child: Text('Go to sale')),
                            SizedBox(height: 10,),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
