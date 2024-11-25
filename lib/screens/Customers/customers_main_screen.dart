import 'package:flutter/material.dart';
import 'package:p_a_jewerly/components/bottom_bar_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BottomBarScreen(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomerHeader(),
            Container(
              height: size.height * 0.7,
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (_, index) {
                  return _CustomerItem(index: index);
                },
              ),
            ),
          ],
        ),
      ),
      actionWidget: CreateUser(),
    );
  }
}

class _CustomerItem extends StatelessWidget {
  const _CustomerItem({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      crossAxisEndOffset: 0.2,
      onDismissed: (direction) {},
      background: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20),
            Icon(Icons.add, color: Colors.white),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 20),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(10),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.amberAccent,
                radius: 20,
                child: Text(index.toString()),
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: Juanit$index de costa btava cortes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Phone: 5532499504'),
                  SizedBox(height: 10),
                  Text('Email: $index@gmail.com'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerHeader extends StatelessWidget {
  const CustomerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 40, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Customer Header',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateUser extends StatelessWidget {
  const CreateUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          _MinSpace(),
          Text(
            'Add a new customer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _MinSpace(),
          _NewCustomerForm(),
          _MinSpace(),
          OutlinedButton(
            onPressed: () {},
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NewCustomerForm extends StatelessWidget {
  const _NewCustomerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Form(
        child: Column(
          children: [
            _CustomerInput(label: 'Name'),
            const _MinSpace(),
            _CustomerInput(label: 'Email'),
            const _MinSpace(),
            _CustomerInput(label: 'Phone'),
          ],
        ),
      ),
    );
  }
}

class _MinSpace extends StatelessWidget {
  const _MinSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 15,
    );
  }
}

class _CustomerInput extends StatelessWidget {
  const _CustomerInput({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autocorrect: false,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
