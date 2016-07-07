# Credential Registry Resources Walkthrough

Currently our API always uses json to send and receive data, so alway use
the `Content-Type: application/json` header on your requests.

We share resource on the  `metadataregistry` by sending `envelopes` of data.

The envelopes are organized in "communities", the CredentialRegistry is a community.

For accessing info about the available communities you can use:

```
GET /api/info
```

almost all resources on our system has an `info` endpoint so you can access
api-docs and metadata about that resource. So, for example, to access info
about the 'credential-registry' community you can do:

```
GET /api/credential-registry/info
```

Each `envelope` has a well defined structure which contains an encoded resource.

These resources are [json-ld](http://json-ld.org/) objects, which has
a [json-schema](http://json-schema.org/) definition. They are encoded,
on the envelope, using [JWT](https://jwt.io/), so you will need and
RSA key pair.

Lets go step-by-step on how to deliver our first envelope of data for the
'credentital_registry' community.

## 1 - Resource

As said before, the resources are community specific and they have a
corresponding json-schema.
The current schema definitions for 'credential-registry' are:

- Organization:
    - [sample schema definition](https://github.com/learningtapestry/metadataregistry/tree/master/docs/sample/credreg-organization-schema.json)
    - get schema from api: `GET /api/schemas/credential_registry/organization`
    - [sample data](https://github.com/learningtapestry/metadataregistry/tree/master/docs/sample/credreg-organization-sample.json)

- Credential:
    - [sample schema definition](https://github.com/learningtapestry/metadataregistry/tree/master/docs/sample/credreg-credential-schema.json)
    - get schema from api: `GET /api/schemas/credential_registry/credential`
    - [sample data](https://github.com/learningtapestry/metadataregistry/tree/master/docs/sample/credreg-credential-sample.json)


The resource json-ld usually uses a context as the following:

```json
"@context": {
  "schema": "http://schema.org/",
  "dc": "http://purl.org/dc/elements/1.1/",
  "dct": "http://dublincore.org/terms/",
  "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
  "cti": "[CTI Namespace Not Determined Yet]"
}
```

And the `@type` *has* to be either `cti:Organization` or `cti:Credential`.

For simplicity, on this example we are going to use the minimal definition bellow:


- create 'resource.json' with the content:
```
{
  "@context": {
    "schema": "http://schema.org/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "dct": "http://dublincore.org/terms/",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "cti": "[CTI Namespace Not Determined Yet]"
  },
  "@type": "cti:Organization",
  "schema:name": "Sample Org"
}
```

## 2 - Encode with JWT

- The first step is to have a RSA key pair, if you don't then check the [README](https://github.com/learningtapestry/metadataregistry/blob/master/README.md#1-generate-a-rsa-key-pair) for info on how to do this.
- You can use any JWT lib to encode, but if you have a ruby environment we provide a script at hand on `bin/jwt_encode`. You can just run:

```shell
ruby bin/jwt_encode resource.json ~/.ssh/id_rsa
```

the output will contain an encoded string for our resource.

## 3 - Generate the envelope

The `envelope` follow this structure:

```
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "credential_registry",
  "resource": /* JWT encoded resource from the previous step */,
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": /* Public key in PEM format, the content from '~/.ssh/id_rsa.pem', be aware of line breaks */
}
```

Where:
- `envelope_type`: Defines the type of the envelope. For now, the only accepted
value is `resource_data`
- `envelope_version`: The version that our envelope is using
- `envelope_community`: The community for this envelope. All envelopes are organized on communities, each of these has different resource schemas. In this case we use `credential_registry`.
- `resource`: The JWT encoded content we just generated
- `resource_format`: Internal format of our resource. Can be `json` or `xml`
- `resource_encoding`: The algorithm used to encode the resource. In our case
it's `jwt`, but in the future we could support other encodings, such as `MIME`
- `resource_public_key`: the public key whose private part was used to sign the
resource. This is strictly needed for signature validation purposes

For our example:

- create an 'envelope.json' with:

```json
{
  "envelope_type": "resource_data",
  "envelope_version": "1.0.0",
  "envelope_community": "credential_registry",
  "resource": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJAY29udGV4dCI6eyJzY2hlbWEiOiJodHRwOi8vc2NoZW1hLm9yZy8iLCJkYyI6Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiwiZGN0IjoiaHR0cDovL2R1YmxpbmNvcmUub3JnL3Rlcm1zLyIsInJkZiI6Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiLCJyZGZzIjoiaHR0cDovL3d3dy53My5vcmcvMjAwMC8wMS9yZGYtc2NoZW1hIyIsImN0aSI6IltDVEkgTmFtZXNwYWNlIE5vdCBEZXRlcm1pbmVkIFlldF0ifSwiQHR5cGUiOiJjdGk6T3JnYW5pemF0aW9uIiwic2NoZW1hOm5hbWUiOiJTYW1wbGUgT3JnIn0.sgCrpnYAqRqZhGbshBjNXyEYiYrTBGUJh2x_mT9_QE9kT0HSWfWYFRXD0_riifl1UuA4HY3YCnFtOiH097tBAIsJhUvEywzUBGoqv5RIOcVOkltngmobJu2ZEONTCBv6cQWurFPIPtwq5W1KkeuE4q5l46kGkD-wNWUY05T5gMA_if5JXfP1_s4UL4Eq5eI8tH7murk_aVa91eaA_YQ_PZOIRXB7jQYeX07-yr_D2bVM4EUqOwW6rdII3-gn6ckMnGxvVPKuBglvTU6uOe1n7bNM5nEfMfBKhavWvsjWxXy30GlCX--Vbmtks_SAm0AgKVQ9rSOVWLD3DzwS503VIg",
  "resource_format": "json",
  "resource_encoding": "jwt",
  "resource_public_key": "-----BEGIN RSA PUBLIC KEY-----\nMIIBCgKCAQEA35JBqCEfCFMuplTm0NvQxnvwAzQHVEUD8yvn6u3uVkKuX9oOPh4r\nKw9j1D7wNK/70oEsvnuBwNWHT7jXdd1bMDiN0d/TPLFllA2u8+Rr8enXU/1WpxH1\nyQxF7lcHyrl07YJ5B3V4PfgdTOR5vm8PB1UxiTNyrdmdeJ0POhphudXUIJF7HGog\ncO3T12fASzjvBod4GQmaMg6Ffm875rw7f5ASPrslbmuQfwDI3wvEQw/Br4Tw0ltV\nGCxbsjCLymnoHS3TNiK9h8v+nGWrz+kz15RMiMkiKNI3CWYph9SANlkHNYycWTP+\nUNUbpT4mqbXSXJN05SdSAJuQotc0SN7/4QIDAQAB\n-----END RSA PUBLIC KEY-----"
}
```

- You can check the `envelope` schema definition on:
    - [sample schema definition](https://github.com/learningtapestry/metadataregistry/tree/master/docs/sample/envelope-schema.json)
    - get schema from api: `GET /api/schemas/envelope`


## 4 - POST to the API:


```
POST /api/credential_registry/envelopes < envelope.json
```

This should return a `201 created` response with the decoded resource in it.

## 5 - Errors:

If any validation error occurs you will probably receive an `422 unprocessable_entity`
with a json containing a list of validation errors. i.e:

```
{
  "errors": [/* list of validation error messages */],
  "json_schema": [ /* list of relevant json-schemas used for this resource validation */]
}
```

Whenever a error happens, you should receive a well descriptive message for
the cause. If that doesn't happen please contact us.

## 6 - Retrieve the resource:

On the success response above you can check the `envelope_id` attribute,
you can use this to retrieve or update the resource. For example:

- if the returned json contains:
```
"envelope_id": "88569f57-3d34-4ba2-9219-24883fdc2fec"
```

- retrieve using:

```
GET /api/credential-registry/envelopes/88569f57-3d34-4ba2-9219-24883fdc2fec
```

## 7 - Updating the resource:

On the POST you could have also passed an 'envelope_id' directly. If you provide a param
`update_if_exists=true` then the system will perform an upsert (i.e: if exists update, else insert) using the provided id.

```
POST /api/credential-registry/envelopes?update_if_exists=true < changed_resource_with_id.json
```

# 8 - Get a list of envelopes

```
GET /api/credential-registry/envelopes
```

 Use the `page` and `per_page` params to control pagination.

 The pagination info is included in the `Link` header.

 ```

Link: <https://example-url.com/api/credential-registry/envelopes?page=3&per_page=100>; rel="next",
  <https://example-url.com/api/credential-registry/envelopes?page=50&per_page=100>; rel="last"
```

The possible rel values are:

- next 	: The link relation for the immediate next page of results.
- last 	: The link relation for the last page of results.
- first :	The link relation for the first page of results.
- prev  :	The link relation for the immediate previous page of results.

-----

For more info check our swagger docs and the json-schemas.
In case of any doubt or sugestion on how to improve this guide, please contact us.
You can provide an issue on github.