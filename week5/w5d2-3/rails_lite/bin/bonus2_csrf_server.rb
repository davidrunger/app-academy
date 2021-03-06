require 'webrick'
require_relative '../lib/controller_base'
require_relative '../lib/flash'
require_relative '../lib/router'


# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

$cats = [
  { id: 1, name: "Curie" },
  { id: 2, name: "Markov" }
]

$statuses = [
  { id: 1, cat_id: 1, text: "Curie loves string!" },
  { id: 2, cat_id: 2, text: "Markov is mighty!" },
  { id: 3, cat_id: 1, text: "Curie is cool!" }
]

class StatusesController < ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:cat_id] == Integer(params[:cat_id])
    end

    render_content(statuses.to_s + flash['notice'].to_s, "text/text")
  end
end

class CatsCsrfController < ControllerBase
  def index
    flash["notice"] = 'your last page was the cats index' if req.path == '/cats'
    render_content($cats.to_s + flash['notice'].to_s, "text/text")
  end

  def new
    render('new')
  end

  def create
    $cats << {params['id'] => params['name']}
    redirect_to('/cats')
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), CatsCsrfController, :index
  get Regexp.new("^/cats/new$"), CatsCsrfController, :new
  post Regexp.new("^/cats$"), CatsCsrfController, :create
  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  route = router.run(req, res)
end

trap('INT') { server.shutdown }
server.start
