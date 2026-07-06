# Coupons Filter API

## Endpoint

- **Method:** `GET`
- **URL:** `/api/coupons/filter`
- **Auth:** No authentication required

## Query Parameters

All parameters are optional.

- `stores`  
  Comma-separated store IDs.  
  Example: `stores=1,3,7`

- `storescategory`  
  Comma-separated store category names.  
  Example: `storescategory=Fashion,Electronics`

- `country`  
  Comma-separated country values/codes used in coupon `country` field.  
  Example: `country=SA,AE`

## Example Requests

### 1) Filter by all parameters

```http
GET /api/coupons/filter?stores=1,3&storescategory=Fashion,Electronics&country=SA,AE
```

### 2) Filter by stores only

```http
GET /api/coupons/filter?stores=2,5
```

### 3) Filter by category + country

```http
GET /api/coupons/filter?storescategory=Beauty&country=SA
```

## Success Response

- **Status:** `200 OK`
- **Body:**

```json
{
  "data": [
    {
      "id": 10,
      "store_id": 3,
      "title": "Coupon title",
      "code": "SAVE10",
      "discount": "10%",
      "country": "SA,AE",
      "country_codes": ["SA", "AE"],
      "country_label": "السعودية، الإمارات",
      "duration": "week",
      "duration_label": "ينتهي خلال أسبوع",
      "link": "https://example.com",
      "image_url": "https://example.com/coupon.jpg",
      "description": "Coupon description",
      "visits": 120,
      "clicks": 35,
      "created_at": "2026-04-09T11:00:00+00:00",
      "badge": "حصري",
      "card_image": "https://example.com/coupon.jpg",
      "store": {
        "id": 3,
        "name": "Store Name",
        "logo_url": "https://example.com/store-logo.png",
        "url": "https://store.com"
      }
    }
  ]
}
```

## Validation Notes

- Each parameter must be a string with max length `255`.
- If a parameter is omitted, it is not used in filtering.
- When no filter is passed, API returns latest coupons (limited by backend limit).

## Flutter (Dio) Example

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost/s5asm/public',
));

Future<List<dynamic>> fetchFilteredCoupons() async {
  final response = await dio.get(
    '/api/coupons/filter',
    queryParameters: {
      'stores': '1,3',
      'storescategory': 'Fashion,Electronics',
      'country': 'SA,AE',
    },
  );

  return (response.data['data'] as List<dynamic>? ?? []);
}
```

## Quick Postman URL

```text
http://localhost/s5asm/public/api/coupons/filter?stores=1,3&storescategory=Fashion,Electronics&country=SA,AE
```
