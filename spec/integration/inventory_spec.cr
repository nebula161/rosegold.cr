require "../spec_helper"

Spectator.describe Rosegold::Bot do
  describe "#pick" do
    context "when the item is not in the inventory" do
      it "returns false" do
        Rosegold::Client.new("localhost", 25565).join_game do |client|
          Rosegold::Bot.new(client).try do |bot|
            bot.chat "/clear"

            sleep 1

            expect(bot.inventory.pick("diamond_pickaxe")).to eq false
            expect(bot.inventory.pick("stone")).to eq false
            expect(bot.inventory.pick("diamond_pickaxe")).to eq false
          end
        end
      end
    end

    context "when the item is in the hotbar" do
      it "returns true" do
        Rosegold::Client.new("localhost", 25565).join_game do |client|
          Rosegold::Bot.new(client).try do |bot|
            bot.chat "/clear"
            sleep 1

            bot.chat "/give #{ENV["MC_NAME"]} minecraft:stone 42"
            bot.chat "/give #{ENV["MC_NAME"]} minecraft:grass_block 43"
            sleep 1

            expect(bot.inventory.pick("stone")).to eq true
            expect(bot.inventory.main_hand.item_id).to eq "stone"
            expect(bot.inventory.pick("grass_block")).to eq true
            expect(bot.inventory.main_hand.item_id).to eq "grass_block"
          end
        end
      end
    end

    context "when the item is in the inventory but not the hotbar" do
      it "returns true" do
        Rosegold::Client.new("localhost", 25565).join_game do |client|
          Rosegold::Bot.new(client).try do |bot|
            bot.chat "/clear"
            sleep 1

            bot.chat "/give #{ENV["MC_NAME"]} minecraft:stone #{64*9}"
            bot.chat "/give #{ENV["MC_NAME"]} minecraft:grass_block 1"
            sleep 1

            expect(bot.inventory.pick("grass_block")).to eq true
            sleep 1
            expect(bot.inventory.main_hand.item_id).to eq "grass_block"
          end
        end
      end
    end
  end

  describe "#pick!" do
    context "when the item is not in the inventory" do
      it "raises exception" do
        Rosegold::Client.new("localhost", 25565).join_game do |client|
          Rosegold::Bot.new(client).try do |bot|
            bot.chat "/clear"
            sleep 1
            expect { bot.inventory.pick!("diamond_pickaxe") }.to raise_error(Rosegold::Inventory::ItemNotFoundError)
          end
        end
      end
    end
  end
end
