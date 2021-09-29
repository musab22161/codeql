/**
 * Provides classes modeling security-relevant aspects of the `fastapi` PyPI package.
 * See https://fastapi.tiangolo.com/.
 */

private import python
private import semmle.python.dataflow.new.DataFlow
private import semmle.python.dataflow.new.RemoteFlowSources
private import semmle.python.dataflow.new.TaintTracking
private import semmle.python.Concepts
private import semmle.python.ApiGraphs

/**
 * Provides models for the `fastapi` PyPI package.
 * See https://fastapi.tiangolo.com/.
 */
private module FastApi {
  /**
   * Provides models for FastAPI applications (an instance of `fastapi.FastAPI`).
   */
  module App {
    /** Gets a reference to a FastAPI application (an instance of `fastapi.FastAPI`). */
    API::Node instance() { result = API::moduleImport("fastapi").getMember("FastAPI").getReturn() }
  }

  /**
   * Provides models for the `fastapi.APIRouter` class
   *
   * See https://fastapi.tiangolo.com/tutorial/bigger-applications/.
   */
  module APIRouter {
    /** Gets a reference to an instance of `fastapi.APIRouter`. */
    API::Node instance() {
      result = API::moduleImport("fastapi").getMember("APIRouter").getReturn()
    }
  }

  // ---------------------------------------------------------------------------
  // routing modeling
  // ---------------------------------------------------------------------------
  /**
   * A call to a method like `get` or `post` on a FastAPI application.
   *
   * See https://fastapi.tiangolo.com/tutorial/first-steps/#define-a-path-operation-decorator
   */
  private class FastApiRouteSetup extends HTTP::Server::RouteSetup::Range, DataFlow::CallCfgNode {
    FastApiRouteSetup() {
      exists(string routeAddingMethod |
        routeAddingMethod = HTTP::httpVerbLower()
        or
        routeAddingMethod = "api_route"
      |
        this = App::instance().getMember(routeAddingMethod).getACall()
        or
        this = APIRouter::instance().getMember(routeAddingMethod).getACall()
      )
    }

    override Parameter getARoutedParameter() {
      // this will need to be refined a bit, since you can add special parameters to
      // your request handler functions that are used to pass in the response. There
      // might be other special cases as well, but as a start this is not too far off
      // the mark.
      result = this.getARequestHandler().getArgByName(_) and
      // type-annotated with `Response`
      not any(Response::RequestHandlerParam src).asExpr() = result
    }

    override DataFlow::Node getUrlPatternArg() {
      result in [this.getArg(0), this.getArgByName("path")]
    }

    override Function getARequestHandler() { result.getADecorator().getAFlowNode() = node }

    override string getFramework() { result = "FastAPI" }
  }

  // ---------------------------------------------------------------------------
  // Response modeling
  // ---------------------------------------------------------------------------
  /**
   * Provides models for the `fastapi.Response` class and subclasses.
   *
   * See https://fastapi.tiangolo.com/advanced/custom-response/#response.
   */
  module Response {
    /**
     * Gets the `API::Node` for the manually modeled response classes called `name`.
     */
    private API::Node getModeledResponseClass(string name) {
      name = "Response" and
      result = API::moduleImport("fastapi").getMember("Response")
      or
      // see https://github.com/tiangolo/fastapi/blob/master/fastapi/responses.py
      name in [
          "Response", "HTMLResponse", "PlainTextResponse", "JSONResponse", "UJSONResponse",
          "ORJSONResponse", "RedirectResponse", "StreamingResponse", "FileResponse"
        ] and
      result = API::moduleImport("fastapi").getMember("responses").getMember(name)
    }

    /**
     * Gets the default MIME type for a FastAPI response class (defined with the
     * `media_type` class-attribute).
     *
     * Also models user-defined classes and tries to take inheritance into account.
     *
     * TODO: build easy way to solve problems like this, like we used to have the
     * `ClassValue.lookup` predicate.
     */
    private string getDefaultMimeType(API::Node responseClass) {
      exists(string name | responseClass = getModeledResponseClass(name) |
        // no defaults for these.
        name in ["Response", "RedirectResponse", "StreamingResponse"] and
        none()
        or
        // For `FileResponse` the code will guess what mimetype
        // to use, or fall back to "text/plain", but claiming that all responses will
        // have "text/plain" per default is also highly inaccurate, so just going to not
        // do anything about this.
        name = "FileResponse" and
        none()
        or
        name = "HTMLResponse" and
        result = "text/html"
        or
        name = "PlainTextResponse" and
        result = "text/plain"
        or
        name in ["JSONResponse", "UJSONResponse", "ORJSONResponse"] and
        result = "application/json"
      )
      or
      // user-defined subclasses
      exists(Class cls, API::Node base |
        cls.getABase() = base.getAUse().asExpr() and
        // since we _know_ that the base has an API Node, that means there is a subclass
        // edge leading to the `ClassExpr` for the class.
        responseClass.getAnImmediateUse().asExpr().(ClassExpr) = cls.getParent()
      |
        exists(Assign assign | assign = cls.getAStmt() |
          assign.getATarget().(Name).getId() = "media_type" and
          result = assign.getValue().(StrConst).getText()
        )
        or
        // TODO: this should use a proper MRO calculation instead
        not exists(Assign assign | assign = cls.getAStmt() |
          assign.getATarget().(Name).getId() = "media_type"
        ) and
        result = getDefaultMimeType(base)
      )
    }

    /**
     * A source of instances of `fastapi.Response` and its' subclasses, extend this class to model new instances.
     *
     * This can include instantiations of the class, return values from function
     * calls, or a special parameter that will be set when functions are called by an external
     * library.
     *
     * Use the predicate `Response::instance()` to get references to instances of `fastapi.Response`.
     */
    abstract class InstanceSource extends DataFlow::LocalSourceNode { }

    /** A direct instantiation of a response class. */
    private class ResponseInstantiation extends InstanceSource, HTTP::Server::HttpResponse::Range,
      DataFlow::CallCfgNode {
      API::Node baseApiNode;
      API::Node responseClass;

      ResponseInstantiation() {
        baseApiNode = getModeledResponseClass(_) and
        responseClass = baseApiNode.getASubclass*() and
        this = responseClass.getACall()
      }

      override DataFlow::Node getBody() {
        not baseApiNode = getModeledResponseClass(["RedirectResponse", "FileResponse"]) and
        result in [this.getArg(0), this.getArgByName("content")]
      }

      override DataFlow::Node getMimetypeOrContentTypeArg() {
        not baseApiNode = getModeledResponseClass("RedirectResponse") and
        result in [this.getArg(3), this.getArgByName("media_type")]
      }

      override string getMimetypeDefault() { result = getDefaultMimeType(responseClass) }
    }

    /**
     * A direct instantiation of a redirect response.
     */
    private class RedirectResponseInstantiation extends ResponseInstantiation,
      HTTP::Server::HttpRedirectResponse::Range {
      RedirectResponseInstantiation() { baseApiNode = getModeledResponseClass("RedirectResponse") }

      override DataFlow::Node getRedirectLocation() {
        result in [this.getArg(0), this.getArgByName("url")]
      }
    }

    /**
     * INTERNAL: Do not use.
     *
     * A parameter to a FastAPI request-handler that has a `fastapi.Response`
     * type-annotation.
     */
    class RequestHandlerParam extends InstanceSource, DataFlow::ParameterNode {
      RequestHandlerParam() {
        this.getParameter().getAnnotation() =
          getModeledResponseClass(_).getASubclass*().getAUse().asExpr() and
        any(FastApiRouteSetup rs).getARequestHandler().getArgByName(_) = this.getParameter()
      }
    }

    /** Gets a reference to an instance of `fastapi.Response`. */
    private DataFlow::TypeTrackingNode instance(DataFlow::TypeTracker t) {
      t.start() and
      result instanceof InstanceSource
      or
      exists(DataFlow::TypeTracker t2 | result = instance(t2).track(t2, t))
    }

    /** Gets a reference to an instance of `fastapi.Response`. */
    DataFlow::Node instance() { instance(DataFlow::TypeTracker::end()).flowsTo(result) }

    /**
     * A call to `set_cookie` on a FastAPI Response.
     */
    private class SetCookieCall extends HTTP::Server::CookieWrite::Range, DataFlow::MethodCallNode {
      SetCookieCall() { this.calls(instance(), "set_cookie") }

      override DataFlow::Node getHeaderArg() { none() }

      override DataFlow::Node getNameArg() { result in [this.getArg(0), this.getArgByName("key")] }

      override DataFlow::Node getValueArg() {
        result in [this.getArg(1), this.getArgByName("value")]
      }
    }

    /**
     * A call to `append` on a `headers` of a FastAPI Response, with the `Set-Cookie`
     * header-key.
     */
    private class HeadersAppendCookie extends HTTP::Server::CookieWrite::Range,
      DataFlow::MethodCallNode {
      HeadersAppendCookie() {
        exists(DataFlow::AttrRead headers, DataFlow::Node keyArg |
          headers.accesses(instance(), "headers") and
          this.calls(headers, "append") and
          keyArg in [this.getArg(0), this.getArgByName("key")] and
          keyArg.getALocalSource().asExpr().(StrConst).getText().toLowerCase() = "set-cookie"
        )
      }

      override DataFlow::Node getHeaderArg() {
        result in [this.getArg(1), this.getArgByName("value")]
      }

      override DataFlow::Node getNameArg() { none() }

      override DataFlow::Node getValueArg() { none() }
    }
  }

  /**
   * Implicit response from returns of FastAPI request handlers
   */
  private class FastApiRequestHandlerReturn extends HTTP::Server::HttpResponse::Range,
    DataFlow::CfgNode {
    FastApiRequestHandlerReturn() {
      exists(Function requestHandler |
        requestHandler = any(FastApiRouteSetup rs).getARequestHandler() and
        node = requestHandler.getAReturnValueFlowNode()
      )
    }

    override DataFlow::Node getBody() { result = this }

    override DataFlow::Node getMimetypeOrContentTypeArg() { none() }

    override string getMimetypeDefault() { result = "application/json" }
  }
}
