def lhfetch(url, headers = {accept: "*/*"})
  # warn "In fetch routine now.  "

  # warn "executing call over the Web to #{url.to_s}"
  response = RestClient::Request.execute({
                                           method: :get,
                                           url: url.to_s,
                                           # user: user,
                                           # password: pass,
                                           headers: headers
                                         })

  # warn "There was a response to the call #{url.to_s}"
  # warn "Response code #{response.code}"
  if response.code == 203
    warn "WARN: Response is non-authoritative (HTTP response code: #{response.code}).  Headers may have been manipulated encountered when trying to resolve #{url}\n"
  end
  [response.headers, response.body]
rescue RestClient::ExceptionWithResponse => e
  warn "EXCEPTION WITH RESPONSE! #{e.response}\n#{e.response.headers}"
  warn "WARN: HTTP error #{e} encountered when trying to resolve #{url}\n"
  if e.response.code == 500
    [false, false]
  else
    [e.response.headers, e.response.body]
  end
# now we are returning the headers and body that were returned
rescue RestClient::Exception => e
  warn "EXCEPTION WITH NO RESPONSE! #{e}"
  warn "WARN: HTTP error #{e} encountered when trying to resolve #{url}\n"
  [false, false]
# now we are returning 'False', and we will check that with an \"if\" statement in our main code
rescue Exception => e
  warn "EXCEPTION UNKNOWN! #{e}"
  warn "WARN: HTTP error #{e} encountered when trying to resolve #{url}\n"
  [false, false]
  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  # you can capture the Exception and do something useful with it!\n",
end
