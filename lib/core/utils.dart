String formatDateTime(String date) {
  if (date.isEmpty) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  var dateTime = date.split('T');
  var onlyDate = dateTime[0].split('-');
  var onlyTime = dateTime[1].split('.')[0].split(':');
  return '${onlyDate[2]} ${months[int.parse(onlyDate[1])]} ${onlyDate[0]}, ${onlyTime[0]}:${onlyTime[1]}';
}
