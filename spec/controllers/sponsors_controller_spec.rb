require 'rails_helper'

describe SponsorsController do
  context 'GET show' do
    let(:petition) { FactoryGirl.create(:petition) }

    it 'fetches the requested petition' do
      get :show, petition_id: petition, token: petition.sponsor_token
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :show, petition_id: petition_param, token: petition.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :show, petition_id: petition, token: petition_2.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the form' do
      get :show, petition_id: petition, token: petition.sponsor_token
      expect(response).to render_template :show
    end

    it 'builds a new sponsor for the petition identified by the token' do
      get :show, petition_id: petition, token: petition.sponsor_token
      expect(assigns[:sponsor]).to be_new_record
      expect(assigns[:sponsor].petition).to eq petition
    end

    it 'builds a signature for the sponsor' do
      get :show, petition_id: petition, token: petition.sponsor_token
      expect(assigns[:stage_manager].signature).to be_present
      expect(assigns[:stage_manager].signature.petition).to eq petition
    end
  end

  context 'PATCH update' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:signature_params) {
      {
        name: 'S. Ponsor',
        email: 's.ponsor@example.com',
        postcode: 'SP1 1NR',
        country: 'United Kingdom',
        uk_citizenship: '1',
        notify_by_email: '0'
      }
    }

    def do_patch(options = {})
      params = {
        petition_id: petition,
        token: petition.sponsor_token,
        signature: signature_params,
        stage: 'replay-email',
        move: 'next'
      }.merge(options)
      patch :update, params
    end

    let(:signature) { petition.signatures.for_email('s.ponsor@example.com').first }

    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        do_patch
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        do_patch token: petition_2.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'with valid signature params' do
      it 'creates a sponsor signature for the petition with the supplied params' do
        do_patch
        expect(signature).to be_present
        expect(signature).to be_sponsor
        expect(signature.name).to eq signature_params[:name]
        expect(signature.postcode).to eq signature_params[:postcode]
        expect(signature.country).to eq signature_params[:country]
        expect(signature.notify_by_email).to eq true
        expect(petition.sponsors.for(signature)).to be_present
      end

      it 'creates the signature in the pending state' do
        do_patch
        expect(signature).to be_pending
        expect(signature.perishable_token).not_to be_nil
      end

      it 'redirects to the thank you page' do
        do_patch
        redirect_url = "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}/thank-you"
        expect(response).to redirect_to redirect_url
      end

      it "allows overriding of the email via params" do
        signature_params[:email] = 'not-the-sponsors-email-address@example.com'
        do_patch
        expect(signature).to be_nil
        created_signature = petition.signatures.for_email('not-the-sponsors-email-address@example.com').first
        expect(created_signature).to be_present
      end

      it "overrides the petition of the signature, no matter what has been passed in" do
        signature_params[:petition_id] = (petition.id + 1000).to_s
        do_patch
        expect(signature.petition).to eq petition
      end

      it "ignores attempts to set the state of signature" do
        signature_params[:state] = 'not-a-state'
        do_patch
        expect(signature).to be_pending
      end

      it "emails the sponsor" do
        do_patch
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq(['s.ponsor@example.com'])
      end
    end

    context 'with invalid signature params' do
      before { signature_params[:name] = '' }

      it 'does not persist the signature' do
        do_patch
        expect(signature).not_to be_present
        expect(assigns[:stage_manager].signature).not_to be_persisted
      end

      it 'renders the form again' do
        do_patch
        expect(response).to render_template :show
      end

      it "has stage of 'signer' if there are errors on name, uk_citizenship, postcode or country" do
        do_patch signature: signature_params.merge(:name => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_patch signature: signature_params.merge(:uk_citizenship => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_patch signature: signature_params.merge(:postcode => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_patch signature: signature_params.merge(:country => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
      end

      it "has stage of 'replay-email' if there are errors on email and we came from 'replay-email' stage" do
        new_signature_params = signature_params.merge(:email => 'foo@')
        do_patch stage: 'replay-email',
                 signature: new_signature_params
        expect(assigns[:stage_manager].stage).to eq 'replay-email'
      end

      it "has stage of 'creator' if there are errors on email and we came from 'signer' stage" do
        new_signature_params = signature_params.merge(:email => 'foo@')
        do_patch stage: 'signer',
                 signature: new_signature_params
        expect(assigns[:stage_manager].stage).to eq 'signer'
      end
    end
  end

  context 'GET thank-you' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:pending_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :thank_you, petition_id: petition, token: petition.sponsor_token
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :thank_you, petition_id: petition_param, token: petition.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :thank_you, petition_id: petition, token: petition_2.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view' do
      get :thank_you, petition_id: petition, token: petition.sponsor_token
      expect(response).to render_template :thank_you
    end
  end

  context 'GET sponsored' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :sponsored, petition_id: petition, token: petition.sponsor_token
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :sponsored, petition_id: petition_param, token: petition.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :sponsored, petition_id: petition, token: petition_2.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view' do
      get :sponsored, petition_id: petition, token: petition.sponsor_token
      expect(response).to render_template :sponsored
    end
  end
end