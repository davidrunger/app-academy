TrelloClone.Views.CardShowView = Backbone.View.extend({
  render: function () {
    var content = this.template({ card: this.model })
    this.$el.html(content);
    return this;
  },

  template: JST['cards/card_show']
})