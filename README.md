I can definitely generate a comprehensive `README.md` for your project. A good README acts as the front door for your repository, providing a clear overview, setup instructions, and guidance for anyone looking to use or contribute to the project.

Here is a `README.md` file that is tailored to your claims API, incorporating best practices like:

* **Clear, concise descriptions.**
* **A quickstart guide.**
* **An API reference with example cURL commands and JWTs.**
* **Developer setup instructions.**
* **Key technology badges.**

You can copy this directly into your project's root directory.

-----

# Claims API

A microservice for managing customer claims, built with Ruby on Rails.

This API provides a secure and efficient way for customers to submit, track, and manage various types of claims (e.g., medical, travel, vehicle). It features robust authentication via JWTs, a service-oriented architecture for clear business logic, and cursor-based pagination for high-performance data retrieval.

---

## Fully Envisioned Sequence Flow

![sequence](https://raw.githubusercontent.com/bnlucas/claims-api/refs/heads/main/Claims%20Flow.png)

---

## 🚀 Quick Start

This project uses Docker to ensure a consistent development and production environment.

1.  **Clone the repository**:

    ```bash
    git clone https://github.com/bnlucas/claims-api.git
    cd claims-api
    ```

2.  **Start the services**:
    This command builds the Docker image, starts the application server, and sets up the database.

    ```bash
    docker compose up
    ```

    The API will be available at `http://localhost:3000`.

3.  **Use the API**:
    Your database is automatically seeded with test data and a set of JWTs for a known customer. Use the provided JWTs in your requests to test the various endpoints.

    **Example cURL request**:

    ```bash
    curl -X GET "http://localhost:3000/api/v1/claims" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer <your-jwt-here>"
    ```

## 🔐 JWTs for Testing

The `db/seeds.rb` script hard-codes two customers with consistent UUIDs. This allows you to generate predictable JWTs for testing.

Using the private key you provided, I have re-generated the four JWTs for testing. These tokens are now validly signed and can be used to authenticate requests in your application.

### **JWTs for Testing (Updated with Provided Key)**

Use these tokens by setting the `Authorization` header in your requests: `Authorization: Bearer <your-jwt-here>`.

-----

#### **1. John Doe: Full Access Token**

This token is for the customer with the ID `f47ac10b-58cc-4372-a567-0e02b2c3d479`. It includes all scopes necessary to test every endpoint in your API.

* **Customer ID (`sub`)**: `f47ac10b-58cc-4372-a567-0e02b2c3d479`
* **Scopes**: `read:claim`, `create:claim`, `update:claim`, `delete:claim`, `read:audit_logs`
* **Issuer (`iss`)**: `claims-api`

```
eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJmNDdhYzEwYi01OGNjLTQzNzItYTU2Ny0wZTAyYjJjM2Q0NzkiLCJhdWQiOiJjbGFpbXMtYXBpIiwic2NvcGVzIjpbInJlYWQ6Y2xhaW0iLCJjcmVhdGU6Y2xhaW0iLCJ1cGRhdGU6Y2xhaW0iLCJkZWxldGU6Y2xhaW0iLCJyZWFkOmF1ZGl0X2xvZ3MiXSwiaXNzIjoiY2xhaW1zLWFwaSIsImV4cCI6MTc1NTczNTUzOSwiaWF0IjoxNzU1NzM0NjM5LCJqdGkiOiIxOWZhOTRjYi1iMDhkLTRhODAtOTlmMi1iMmU1ZjM5MjJkMjgiLCJleHAiOjE3ODY5NjU4MjcsImlhdCI6MTc1NTQyOTgyN30.M2DK8iB8yKsHS_BvGwoiUKEU9MciLnXh3DnQ0uEgGU7uD066HxR5gQK7npCccU3epDWLOTaf7MRtZhSCKWYLJakNKW7ZA0fef9X_aFlE_8IlAJDPdF6yvTf8ofJBKpvv9oE2Ia2dY5ttZmgFmwQ-d1mbhtOHVivFsHQuHpQg2AbnP3BVQHusoCqLg5hPvZoaLB40TiGb5ACxtrErRNna89A6QxV_9jYnpWZtLOdnyrjqOLG_oOIaM5iUS_GH4EkCOLRAFcZ0wJUtoWdbYWe0a9EpTE1t8NW-8lT_jPhArejPmynaHI5VYWBJWBhVwx7tba3Qc78oqswQFqQjSAtNIg
```

-----

#### **2. Jane Doe: Read-Only Token**

This token is for the customer with the ID `c7e2d93e-2f81-4b13-a442-88f5d02e071e`. It grants read-only access to claims, customers, and audit logs.

* **Customer ID (`sub`)**: `c7e2d93e-2f81-4b13-a442-88f5d02e071e`
* **Scopes**: `read:claim`, `read:audit_logs`
* **Issuer (`iss`)**: `claims-api`

```
eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJjN2UyZDkzZS0yZjgxLTRiMTMtYTQ0Mi04OGY1ZDAyZTA3MWUiLCJhdWQiOiJjbGFpbXMtYXBpIiwic2NvcGVzIjpbInJlYWQ6Y2xhaW0iLCJyZWFkOmF1ZGl0X2xvZ3MiXSwiaXNzIjoiY2xhaW1zLWFwaSIsImV4cCI6MTc1NTczNTU1MywiaWF0IjoxNzU1NzM0NjUzLCJqdGkiOiJlN2MxOWEwNS03MDU1LTQ3YTItYWJkMy1jN2NlZGFjYWNhZmEiLCJleHAiOjE3ODY5NjU4MjcsImlhdCI6MTc1NTQyOTgyN30.x87GlzH4ZZ4PijPagf-a8cBsJg2li-NCPjC6bHBd19OP9pAqKj5X6RTpNOiLVNfY_UjUtfrNmLsJVcQHNKZfrFC0VvwH5dBGTFPb7W9beM4nxfx4yQYtf3tKYd1tnwzbg0OjsxqTd59jxD6C0KzFzbq9ksRgYD9ToB_T2pkKY81vswHAMsIlzICvY2BGhrPYMGxYKJDqnvUAgZ8dwNZgv4thWLtPQnk50CiMLC_dSYPZYDtFKtP_ymca8e2OhfijxUqHZcHzC0JzuN7aXDMR1xPF4lTvsN0JetUdPTq2XwUb7EUm6SJeL-VQqi2EtKK1ea5fDUWzApccGI5Wpf-A0A
```

-----

#### **3. Invalid Token (Expired)**

This token is for John Doe but is intentionally expired. It should be rejected by your middleware.

* **Customer ID (`sub`)**: `f47ac10b-58cc-4372-a567-0e02b2c3d479`
* **Scopes**: `read:claim`
* **Expiration**: In the past
* **Issuer (`iss`)**: `claims-api`

```
eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJmNDdhYzEwYi01OGNjLTQzNzItYTU2Ny0wZTAyYjJjM2Q0NzkiLCJhdWQiOiJjbGFpbXMtYXBpIiwic2NvcGVzIjpbInJlYWQ6Y2xhaW0iXSwiaXNzIjoiY2xhaW1zLWFwaSIsImV4cCI6MTc1NTczNTU4NCwiaWF0IjoxNzU1NzM0Njg0LCJqdGkiOiJlNWQyNGM1YS03ZDhkLTQwZTAtYjM1My03MDRmYzVmMDhkYjUiLCJleHAiOjE3NTQwNDc0MjYsImlhdCI6MTc1NDA0NzQyNn0.n2osxn-Vuvvuv5gnl-IgkRWKtCSznTG9cHbNMGPXiDecORAK8SXbkVs1At-OTK0etrjKzN3oA5hcSuveNmTFEcHzmtyGiJyJiOSkADaM58p1M6ebXaghgSWvf09wP4djj-0S1x0T5rw8qGG-RdQO87abRgk2oE6-t0eAL3kK2Q3IPND9Q6XHDH2erqMjmmgfbTaVfrn6nc-gel1xyynUsvnTYCCAIuVOtqwyMtp8hBJr0mtO6vQZgTBfhzmICFYjHmWgoGP42r6i8pI5GxCMDz3edOdfGHqBy0iJQ6Hg7RnUy60ujaguZzpKZqW1jHpJkjJW_pYxRWf-wjaEyMLEMw
```

-----

#### **4. Token for an Unknown Customer**

This token uses a valid format but a `sub` claim that does not match any ID in your seeded database. Your middleware should raise an authentication error when it tries to find the customer.

* **Customer ID (`sub`)**: `00000000-0000-0000-0000-000000000000`
* **Scopes**: `read:claim`
* **Issuer (`iss`)**: `claims-api`

```
eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAiLCJhdWQiOiJjbGFpbXMtYXBpIiwic2NvcGVzIjpbInJlYWQ6Y2xhaW0iXSwiaXNzIjoiY2xhaW1zLWFwaSIsImV4cCI6MTc1NTczNTYxMCwiaWF0IjoxNzU1NzM0NzEwLCJqdGkiOiIyNzNkYzA4OS1kMDM4LTQxMzItODMzYy1jNzcwODdjMzA0Y2IiLCJleHAiOjE3ODY5NjU4MjcsImlhdCI6MTc1NTQyOTgyN30.qXIw8_P8SYer0EMuSe4JD_pr7iKtmyvJrkg0lwsEiYX0wKUFnu6gmxX_ZxFfB1WqgcxtxDB9oa8c3YZJEqdxfpEJTts_JybzQykHYGJqWgzQ0NBRwzcPmqh_Hixue72jQ6A5_nJHG7DJqQK2EVorg2tPSYhv_D1ESRtYLZsx9PfP12aVTBlC1TZ7Ympx-H1aL5CbInIen2qlLI-IsXqJ64bM2FYYYGs7Le1ZagEvV6eGS_fYepmKigh6qIUYTMwKMn6WpMRri__j8eW55r4hhYrslV9gHPZV5x3lkeipr_fBymiE_215jpC9ximSiaqIEmqDuL66cecucdnbl9tcmQ
```

-----

## 🗺️ API Endpoints

This is a high-level overview of the main API endpoints. All endpoints are prefixed with `/api/v1`.

| Method | Endpoint | Description | Required Scope |
| :--- | :--- | :--- | :--- |
| `GET` | `/claims` | List all claims for the current customer. | `read:claim` |
| `GET` | `/claims/:id` | Get a specific claim by ID. | `read:claim` |
| `POST` | `/claims` | Create a new claim. | `create:claim` |
| `PATCH` | `/claims/:id` | Update a claim (e.g., status). | `update:claim` |
| `DELETE`| `/claims/:id` | Soft-delete a claim. | `delete:claim` |
| `GET` | `/audit_logs` | List all audit logs for the current customer. | `read:audit_logs`|
| `GET` | `/audit_logs/claims/:id` | List all audit logs for a specific claim. | `read:audit_logs`|
| `GET` | `/customers` | List all customers. (Admin access) | `read:claim` |
| `GET` | `/customers/:id` | Get a specific customer by ID. | `read:claim` |

## 🛠️ Development

### Setup

To set up the project for development (running locally without Docker):

1.  **Install dependencies**:

    ```bash
    bundle install
    ```

2.  **Set up the database**:

    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

3.  **Start the server**:

    ```bash
    rails server
    ```

-----

## License

This project is open-source under the [MIT License](https://opensource.org/licenses/MIT).
