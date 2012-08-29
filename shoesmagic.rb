
Shoes.app do

stack do
  button("load http://store.wrightstuff.biz/catalog.xml") {
    alert("retrieving...")
    # get xml payload
    if File.exist? "catalog.xml"
        para "catalog.xml has already been automatically downloaded, using existing"
        @wsdata = IO.read("catalog.xml")
    else
        download "http://store.wrightstuff.biz/catalog.xml",
            :save => "catalog.xml" do
              @status.text = "Okay, is downloaded."
        end
        #File.open("catalog.xml", "wb") { |f| f << wsdata.read }
    end
  }

  button("get the item data") {
    @items = @data.css("Item[TableID=new-item]").map { |item| item }
    @itemids = @data.css("Item[TableID=new-item]").map { |item| item['ID'] }
    alert(@itemids.first)
  }


end

end
