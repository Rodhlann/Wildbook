package org.ecocean;

/*
   import java.net.URL;
   import java.util.ArrayList;
   import java.util.Arrays;
   import java.util.HashSet;
   import java.util.List;
   import java.util.Properties;
   import java.util.Random;
   import javax.servlet.http.HttpServletRequest;
   import org.ecocean.datacollection.*;
   import org.ecocean.media.Feature;
   import org.ecocean.media.MediaAsset;
   import org.ecocean.media.MediaAssetFactory;
   import org.ecocean.media.URLAssetStore;
   import org.ecocean.movement.*;
   import org.ecocean.servlet.ServletUtilities;
   import org.joda.time.DateTime;
   import org.json.JSONArray;
   import org.json.JSONObject;

   import java.io.IOException;
   import java.net.MalformedURLException;
   import java.security.InvalidKeyException;
   import java.security.NoSuchAlgorithmException;
   import org.apache.shiro.crypto.hash.Sha256Hash;
 */
import java.io.StringReader;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import org.json.JSONObject;

/*
   import org.apache.hc.client5.http.auth.AuthScope;
   import org.apache.hc.client5.http.auth.UsernamePasswordCredentials;
   import org.apache.hc.client5.http.impl.auth.BasicCredentialsProvider;
   import org.apache.hc.client5.http.impl.nio.PoolingAsyncClientConnectionManager;
   import org.apache.hc.client5.http.impl.nio.PoolingAsyncClientConnectionManagerBuilder;
   import org.apache.hc.client5.http.ssl.ClientTlsStrategyBuilder;
   import org.apache.hc.core5.function.Factory;
   import org.apache.hc.core5.http.HttpHost;
   import org.apache.hc.core5.http.nio.ssl.TlsStrategy;
   import org.apache.hc.core5.reactor.ssl.TlsDetails;
   import org.apache.hc.core5.ssl.SSLContextBuilder;
 */

import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.HttpHost;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.nio.client.HttpAsyncClientBuilder;
import org.opensearch.client.json.jackson.JacksonJsonpMapper;
import org.opensearch.client.RestClient;
import org.opensearch.client.RestClientBuilder;
import org.opensearch.client.transport.rest_client.RestClientTransport;

import org.opensearch.client.json.jackson.JacksonJsonpMapper;
import org.opensearch.client.opensearch.core.IndexRequest;
import org.opensearch.client.opensearch.core.IndexResponse;
import org.opensearch.client.opensearch.indices.CreateIndexRequest;
import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.transport.httpclient5.ApacheHttpClient5TransportBuilder;
import org.opensearch.client.transport.OpenSearchTransport;

// https://opensearch.org/docs/latest/clients/java/
// https://github.com/opensearch-project/opensearch-java/blob/main/USER_GUIDE.md

public class OpenSearch {
    public static OpenSearchClient client = null;
    // public static Properties props = null; // will be set by init()

    public OpenSearch() {
        // System.setProperty("javax.net.ssl.trustStore", "/full/path/to/keystore");
        // System.setProperty("javax.net.ssl.trustStorePassword", "password-to-keystore");

        // final HttpHost host = new HttpHost("http", "opensearch", 9200);
        final HttpHost host = new HttpHost("opensearch", 9200, "http");
/*
    final BasicCredentialsProvider credentialsProvider = new BasicCredentialsProvider();
    // Only for demo purposes. Don't specify your credentials in code.
    credentialsProvider.setCredentials(new AuthScope(host), new UsernamePasswordCredentials("admin", "admin".toCharArray()));

    final SSLContext sslcontext = SSLContextBuilder
      .create()
      .loadTrustMaterial(null, (chains, authType) -> true)
      .build();
 */

        //////final ApacheHttpClient5TransportBuilder builder = ApacheHttpClient5TransportBuilder.builder(host);
/*
    builder.setHttpClientConfigCallback(httpClientBuilder -> {
      final TlsStrategy tlsStrategy = ClientTlsStrategyBuilder.create()
        .setSslContext(sslcontext)
        // See https://issues.apache.org/jira/browse/HTTPCLIENT-2219
        .setTlsDetailsFactory(new Factory<SSLEngine, TlsDetails>() {
          @Override
          public TlsDetails create(final SSLEngine sslEngine) {
            return new TlsDetails(sslEngine.getSession(), sslEngine.getApplicationProtocol());
          }
        })
        .build();

      final PoolingAsyncClientConnectionManager connectionManager = PoolingAsyncClientConnectionManagerBuilder
        .create()
        .setTlsStrategy(tlsStrategy)
        .build();

      return httpClientBuilder
        .setDefaultCredentialsProvider(credentialsProvider)
        .setConnectionManager(connectionManager);
    });
 */

        /////final OpenSearchTransport transport = builder.build();
        final RestClient restClient = RestClient.builder(host).build();
        final OpenSearchTransport transport = new RestClientTransport(restClient,
            new JacksonJsonpMapper());

        client = new OpenSearchClient(transport);
        System.out.println("got client???? " + client);
    }

/*
    public static void init(HttpServletRequest request) {
        init(ServletUtilities.getContext(request));
    }

    // should be called once -- sets up credentials for REST calls
    public static void init(String context) {
        if (props == null)
            props = ShepherdProperties.getProperties("opensearch.properties", "", context);
        if (props == null) throw new RuntimeException("no opensearch.properties");
        apiUsername = props.getProperty("apiUsername");
        apiPassword = props.getProperty("apiPassword");
    }
 */
    public void createIndex(String indexName)
    throws java.io.IOException {
        CreateIndexRequest createIndexRequest = new CreateIndexRequest.Builder().index(
            indexName).build();

        client.indices().create(createIndexRequest);
    }

    public void index(JSONObject jobj, String indexName)
    throws java.io.IOException {
        String id = jobj.optString("id", null);

        if (id == null) throw new RuntimeException("must have id property to index");
        IndexRequest<JSONObject> indexRequest = new IndexRequest.Builder<JSONObject>()
                .index(indexName)
                .id(id)
                .document(jobj)
                .build();
        IndexResponse indexResponse = client.index(indexRequest);
        System.out.println(String.format("Document %s.",
            indexResponse.result().toString().toLowerCase()));
    }
}
