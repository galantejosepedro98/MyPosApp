import 'package:flutter/material.dart';

class ProductItem extends StatelessWidget {
  final int index;
  final String name;
  final double price;
  final int quantity;
  final Function? addItem;
  final Function? updateQuantity;
  const ProductItem(
      {super.key,
      this.index = 0,
      this.name = 'Product name',
      this.price = 0.0,
      this.quantity = 0,
      this.addItem,
      this.updateQuantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Color(index % 2 == 0 ? 0xff28badf : 0xffec6031),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 5)
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$price€',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                width: 10,
              ),              // Using InkWell instead of GestureDetector for better Android compatibility
              InkWell(
                onTap: () {
                  print('Remove button tapped for $name');
                  if (quantity > 0 && updateQuantity != null) {
                    try {
                      updateQuantity!(-1);
                      print('updateQuantity called successfully for $name');
                    } catch (e) {
                      print('ERROR calling updateQuantity: $e');
                    }
                  } else {
                    print('Cannot remove: quantity=$quantity, updateQuantity=${updateQuantity != null}');
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                width: 8,
              ),              // Using InkWell instead of GestureDetector for better Android compatibility
              InkWell(
                onTap: () {
                  print('Add button tapped for $name');
                  if (addItem != null) {
                    try {
                      addItem!();
                      print('addItem called successfully for $name');
                    } catch (e) {
                      print('ERROR calling addItem: $e');
                    }
                  } else {
                    print('addItem is null for $name');
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
