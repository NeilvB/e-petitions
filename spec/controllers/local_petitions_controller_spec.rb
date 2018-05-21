require 'rails_helper'

RSpec.describe LocalPetitionsController, type: :controller do
  let(:parish) { FactoryBot.create(:parish, external_id: "99999", name: "Holborn") }

  describe "GET /petitions/local" do
    context "when the postcode is valid" do
      before do
        expect(Parish).to receive(:find_by_postcode).with("N11TY").and_return(parish)

        get :index, params: { postcode: "n1 1ty" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("N11TY")
      end

      it "redirects to the parish page for current popular petitions" do
        expect(response).to redirect_to("/petitions/local/holborn")
      end
    end

    context "when the postcode is invalid" do
      before do
        expect(Parish).to receive(:find_by_postcode).with("SW1A1AA").and_return(nil)
        get :index, params: { postcode: "sw1a 1aa" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("SW1A1AA")
      end

      it "responds successfully" do
        expect(response).to be_success
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end

      it "doesn't assign the parish" do
        expect(assigns(:parish)).to be_nil
      end

      it "doesn't assign the petitions" do
        expect(assigns(:petitions)).to be_nil
      end
    end

    context "when the postcode is blank" do
      before do
        expect(Parish).not_to receive(:find_by_postcode)
        get :index, params: { postcode: "" }
      end

      it "responds successfully" do
        expect(response).to be_success
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end

    context "when the postcode is not set" do
      before do
        expect(Parish).not_to receive(:find_by_postcode)
        get :index
      end

      it "responds successfully" do
        expect(response).to be_success
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end
  end

  describe "GET /petitions/local/:id" do
    let(:petitions) { double(:petitions) }

    before do
      expect(Parish).to receive(:find_by_slug!).with("holborn").and_return(parish)
      expect(Petition).to receive(:popular_in_parish).with("99999", 50).and_return(petitions)

      get :show, params: { id: "holborn" }
    end

    it "renders the show template" do
      expect(response).to render_template("local_petitions/show")
    end

    it "assigns the parish" do
      expect(assigns(:parish)).to eq(parish)
    end

    it "assigns the petitions" do
      expect(assigns(:petitions)).to eq(petitions)
    end
  end

  describe "GET /petitions/local/:id/all" do
    let(:petitions) { double(:petitions) }

    before do
      expect(Parish).to receive(:find_by_slug!).with("holborn").and_return(parish)
      expect(Petition).to receive(:all_popular_in_parish).with("99999", 50).and_return(petitions)

      get :all, params: { id: "holborn" }
    end

    it "renders the all template" do
      expect(response).to render_template("local_petitions/all")
    end

    it "assigns the parish" do
      expect(assigns(:parish)).to eq(parish)
    end

    it "assigns the petitions" do
      expect(assigns(:petitions)).to eq(petitions)
    end
  end
end
